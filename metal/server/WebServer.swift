import Foundation
import SwiftUI
import Combine
import FlyingFox

// MARK: - Web Server

/// HTTP server for web-based remote control
@MainActor
class WebServer: ObservableObject {
    static let shared = WebServer()

    // MARK: - Published State
    @Published var isRunning: Bool = false
    @Published var localURL: String = ""
    @Published var publicURL: String = ""
    @Published var error: String? = nil

    // MARK: - Private Properties
    private var server: HTTPServer?
    private var ngrokManager = NgrokManager()
    private var agentState = AgentState()  // Separate state for web tasks
    private var logCancellable: AnyCancellable?

    // Log Management for Polling
    private var recentLogs: [LogEntryDTO] = []
    private let maxRecentLogs = 100

    private init() {}

    // MARK: - Server Lifecycle

    /// Start the web server and ngrok tunnel
    func start(port: UInt16 = 8080) async throws {
        guard !isRunning else { return }

        LogManager.shared.info("Starting web server on port \(port)...")

        let server = HTTPServer(port: port)

        // Register routes
        await server.appendRoute("GET /") { request async throws -> HTTPResponse in
            return try await self.handleRoot(request)
        }

        await server.appendRoute("POST /api/task") { request async throws -> HTTPResponse in
            return try await self.handleTask(request)
        }

        await server.appendRoute("GET /api/logs") { request async throws -> HTTPResponse in
            return try await self.handleLogs(request)
        }

        await server.appendRoute("GET /api/status") { request async throws -> HTTPResponse in
            return try await self.handleStatus(request)
        }

        self.server = server
        self.localURL = "http://localhost:\(port)"
        self.isRunning = true

        // Setup log observer
        setupLogObserver()

        // Start ngrok tunnel
        startNgrok(port: port)

        LogManager.shared.success("Web server started successfully")

        // Run server in background (this blocks until stopped)
        Task.detached {
            try? await server.run()
        }
    }

    /// Stop the web server and ngrok
    func stop() {
        guard isRunning else { return }

        LogManager.shared.info("Stopping web server...")

        // Stop ngrok
        ngrokManager.stop()

        // Stop log observer
        logCancellable?.cancel()
        logCancellable = nil

        // Stop FlyingFox server
        Task {
            await server?.stop()
        }

        isRunning = false
        localURL = ""
        publicURL = ""
        error = nil
        recentLogs = []

        LogManager.shared.info("Web server stopped")
    }

    // MARK: - Route Handlers

    /// Handle GET / - Serve web UI
    private func handleRoot(_ request: HTTPRequest) async throws -> HTTPResponse {
        // Load HTML from bundle
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html"),
              let htmlData = try? Data(contentsOf: URL(fileURLWithPath: htmlPath)),
              let htmlString = String(data: htmlData, encoding: .utf8) else {
            return HTTPResponse(statusCode: .notFound, body: Data("HTML file not found".utf8))
        }

        return HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "text/html; charset=utf-8"],
            body: Data(htmlString.utf8)
        )
    }

    /// Handle POST /api/task - Submit task
    private func handleTask(_ request: HTTPRequest) async throws -> HTTPResponse {
        let bodyData = try await request.bodyData
        guard let taskRequest = try? JSONDecoder().decode(TaskRequest.self, from: bodyData) else {
            let response = TaskResponse(success: false, message: "Invalid request", error: "Missing or invalid task")
            return try encodeResponse(response)
        }

        let taskResponse = await handleTaskRequest(task: taskRequest.task)
        return try encodeResponse(taskResponse)
    }

    /// Handle GET /api/logs - Return recent logs (polling endpoint)
    private func handleLogs(_ request: HTTPRequest) async throws -> HTTPResponse {
        let logs = recentLogs
        return try encodeResponse(logs)
    }

    /// Handle GET /api/status - Agent status
    private func handleStatus(_ request: HTTPRequest) async throws -> HTTPResponse {
        let status = await handleStatusRequest()
        return try encodeResponse(status)
    }

    /// Helper to encode JSON response
    private func encodeResponse<T: Encodable>(_ value: T) throws -> HTTPResponse {
        let data = try JSONEncoder().encode(value)
        return HTTPResponse(
            statusCode: .ok,
            headers: [.contentType: "application/json"],
            body: data
        )
    }

    // MARK: - Log Observer

    /// Setup observer for LogManager changes
    private func setupLogObserver() {
        logCancellable = LogManager.shared.$logs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                guard let self = self, let lastLog = logs.last else { return }
                let dto = LogEntryDTO(from: lastLog)
                self.recentLogs.append(dto)

                // Keep only recent logs
                if self.recentLogs.count > self.maxRecentLogs {
                    self.recentLogs.removeFirst(self.recentLogs.count - self.maxRecentLogs)
                }
            }
    }

    // MARK: - ngrok Integration

    /// Start ngrok tunnel
    private func startNgrok(port: UInt16) {
        ngrokManager.start(port: port) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let url):
                    self?.publicURL = url
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                    LogManager.shared.warning("ngrok failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Business Logic Handlers

    /// Handle POST /api/task
    private func handleTaskRequest(task: String) async -> TaskResponse {
        // Validate task
        guard !task.isEmpty, task.count <= 1000 else {
            return TaskResponse(
                success: false,
                message: "Invalid task",
                error: "Task must be between 1 and 1000 characters"
            )
        }

        // Check if agent is already running
        guard agentState.stopped else {
            return TaskResponse(
                success: false,
                message: "Agent is busy",
                error: "Another task is currently running"
            )
        }

        // Start task on main actor
        let agent = Agent(state: agentState)
        agent.start(task: task)

        return TaskResponse(success: true, message: "Task started")
    }

    /// Handle GET /api/status
    private func handleStatusRequest() -> AgentStatus {
        return AgentStatus(
            nSteps: agentState.nSteps,
            stopped: agentState.stopped,
            currentTask: agentState.currentTask,
            lastGoal: agentState.lastModelOutput?.nextGoal
        )
    }
}
