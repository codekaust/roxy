import Foundation

struct ParamSpec {
    let name: String
    let type: String // "String", "Int", "Bool"
    let description: String
}

struct ActionSpec {
    let name: String
    let description: String
    let params: [ParamSpec]
}
// MARK: - 1. The Action Enum
enum Action: Codable {
    case tap(TapPayload)
    case type(TypePayload)
    case pressKey(PressKeyPayload)
    case scroll(ScrollPayload)
    case openApp(OpenAppPayload)
    case speak(SpeakPayload)
    case wait(WaitPayload)
    case back(NoArgsPayload)
    case home(NoArgsPayload)
    case readFile(ReadFilePayload)
    case writeFile(WriteFilePayload)
    case appendFile(AppendFilePayload)
    case done(DonePayload)

    static var allSpecs: [ActionSpec] {
        return [
            ActionSpec(
                name: "tap",
                description: "Click on an interactive element by its numeric index.",
                params: [
                    ParamSpec(name: "index", type: "Int", description: "The [x] index from mac_state.")
                ]
            ),
            ActionSpec(
                name: "type",
                description: "Type text into the currently focused field.",
                params: [
                    ParamSpec(name: "text", type: "String", description: "Text to type.")
                ]
            ),
            ActionSpec(
                name: "press_key",
                description: "Press a single keyboard key (arrow keys, enter, escape, function keys, etc.).",
                params: [
                    ParamSpec(name: "key", type: "String", description: "Key name (e.g., 'enter', 'escape', 'left', 'right', 'up', 'down', 'tab', 'space', 'f1', 'home', 'end', 'pageup', 'pagedown')")
                ]
            ),
            ActionSpec(
                name: "scroll",
                description: "Scroll the screen content.",
                params: [
                    ParamSpec(name: "amount", type: "Int", description: "Positive for Down, Negative for Up.")
                ]
            ),
            ActionSpec(
                name: "open_app",
                description: "Launch or switch to an application.",
                params: [
                    // Note: 'app_name' matches the CodingKey in OpenAppPayload
                    ParamSpec(name: "app_name", type: "String", description: "Name of the app (e.g. 'Safari').")
                ]
            ),
            ActionSpec(
                name: "wait",
                description: "Wait for 2 seconds to let UI load.",
                params: [
                    ParamSpec(name: "duration", type: "String", description: "Specify the duration in seconds")
                ]
            ),
            ActionSpec(
                name: "read_file",
                description: "Read contents of a file in documents.",
                params: [
                    ParamSpec(name: "file_name", type: "String", description: "Name of the file to read.")
                ]
            ),
            ActionSpec(
                name: "write_file",
                description: "Overwrite a file in documents.",
                params: [
                    ParamSpec(name: "file_name", type: "String", description: "Name of the file."),
                    ParamSpec(name: "content", type: "String", description: "Content to write.")
                ]
            ),
            ActionSpec(
                name: "append_file",
                description: "Append content to a file in documents.",
                params: [
                    ParamSpec(name: "file_name", type: "String", description: "Name of the file."),
                    ParamSpec(name: "content", type: "String", description: "Content to append.")
                ]
            ),
            ActionSpec(
                name: "done",
                description: "Call this when the user task is finished or impossible.",
                params: [
                    ParamSpec(name: "success", type: "Bool", description: "True if task succeeded."),
                    ParamSpec(name: "text", type: "String", description: "Final report to user."),
                    ParamSpec(name: "files_to_display", type: "List<String>", description: "Optional list of files to show.")
                ]
            ),
            ActionSpec(
                name: "speak",
                description: "Speak a message aloud to the user.",
                params: [
                    ParamSpec(name: "message", type: "String", description: "The text to speak.")
                ]
            )
        ]
    }

    // JSON Keys
    enum CodingKeys: String, CodingKey {
        case tap, type, scroll, done, wait, back, home
        case pressKey = "press_key"
        case openApp = "open_app"
        case readFile = "read_file"
        case writeFile = "write_file"
        case appendFile = "append_file"
        case searchGoogle = "search_google"
        case speak
    }
    
    // Decoding Logic
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let val = try? container.decode(TapPayload.self, forKey: .tap) { self = .tap(val) }
        else if let val = try? container.decode(TypePayload.self, forKey: .type) { self = .type(val) }
        else if let val = try? container.decode(PressKeyPayload.self, forKey: .pressKey) { self = .pressKey(val) }
        else if let val = try? container.decode(ScrollPayload.self, forKey: .scroll) { self = .scroll(val) }
        else if let val = try? container.decode(OpenAppPayload.self, forKey: .openApp) { self = .openApp(val) }
        else if let val = try? container.decode(SpeakPayload.self, forKey: .speak) { self = .speak(val) }
        else if let val = try? container.decode(WaitPayload.self, forKey: .wait) { self = .wait(val) }
        else if let val = try? container.decode(ReadFilePayload.self, forKey: .readFile) { self = .readFile(val) }
        else if let val = try? container.decode(WriteFilePayload.self, forKey: .writeFile) { self = .writeFile(val) }
        else if let val = try? container.decode(AppendFilePayload.self, forKey: .appendFile) { self = .appendFile(val) }
        else if let val = try? container.decode(DonePayload.self, forKey: .done) { self = .done(val) }
        else if container.contains(.back) { self = .back(NoArgsPayload()) }
        else if container.contains(.home) { self = .home(NoArgsPayload()) }
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unknown Action"))
        }
    }
    
    // Encoding Logic
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .tap(let val): try container.encode(val, forKey: .tap)
        case .type(let val): try container.encode(val, forKey: .type)
        case .pressKey(let val): try container.encode(val, forKey: .pressKey)
        case .scroll(let val): try container.encode(val, forKey: .scroll)
        case .openApp(let val): try container.encode(val, forKey: .openApp)
        case .speak(let val): try container.encode(val, forKey: .speak)
        case .wait(let val): try container.encode(val, forKey: .wait)
        case .readFile(let val): try container.encode(val, forKey: .readFile)
        case .writeFile(let val): try container.encode(val, forKey: .writeFile)
        case .appendFile(let val): try container.encode(val, forKey: .appendFile)
        case .done(let val): try container.encode(val, forKey: .done)
        case .back: try container.encode(NoArgsPayload(), forKey: .back)
        case .home: try container.encode(NoArgsPayload(), forKey: .home)
        }
    }
}

// MARK: - 2. Payload Structs

struct NoArgsPayload: Codable {}

struct TapPayload: Codable { let index: Int }
struct TypePayload: Codable { let text: String }
struct PressKeyPayload: Codable { let key: String }

struct ScrollPayload: Codable {
    let amount: Int
}

struct OpenAppPayload: Codable {
    let appName: String
    enum CodingKeys: String, CodingKey { case appName = "app_name" }
}

struct SpeakPayload: Codable { let message: String }
struct WaitPayload: Codable { let duration: String }

struct ReadFilePayload: Codable {
    let fileName: String
    enum CodingKeys: String, CodingKey { case fileName = "file_name" }
}

struct WriteFilePayload: Codable {
    let fileName: String
    let content: String
    enum CodingKeys: String, CodingKey { case fileName = "file_name"; case content }
}

struct AppendFilePayload: Codable {
    let fileName: String
    let content: String
    enum CodingKeys: String, CodingKey { case fileName = "file_name"; case content }
}

struct DonePayload: Codable {
    let success: Bool
    let text: String
    let filesToDisplay: [String]?
    
    enum CodingKeys: String, CodingKey {
        case success, text
        case filesToDisplay = "files_to_display"
    }
}
