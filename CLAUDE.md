# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Roxy** (formerly "metal") is a voice-controlled macOS automation agent built with SwiftUI. It uses Google Gemini LLM to interpret voice commands and autonomously control the macOS desktop through accessibility APIs, following an OODA loop pattern (Observe → Orient → Decide → Act).

Product Name: **Roxy**
Bundle ID: `org.roxyorg.roxy`
Xcode Project: `metal.xcodeproj` (target: `metal`, output: `Roxy.app`)

## Building and Running

```bash
# Build the app (creates Roxy.app)
xcodebuild -scheme metal -configuration Release build

# Build for development/debugging
xcodebuild -scheme metal -configuration Debug build

# Run tests
xcodebuild -scheme metal test

# Clean build artifacts
xcodebuild -scheme metal clean
```

The built app is located at: `build/Build/Products/Release/Roxy.app`

**Important:** The app requires macOS 15.5+ and needs Accessibility permissions to function.

## Configuration

API keys are managed by `ConfigurationManager` (metal/utilities/ConfigurationManager.swift) with priority:
1. macOS Keychain (preferred, set via Settings UI)
2. `.env` file in project root (for development)

Required API keys:
- `GEMINI_API_KEY` - Google Gemini LLM (gemini-3-flash-preview)
- `GOOGLE_TTS_API_KEY` - Google Cloud Text-to-Speech
- `GOOGLE_STT_API_KEY` - Google Cloud Speech-to-Text

Copy `.env.example` to `.env` and add your keys for local development.

## Architecture

### Two-Layer System

**1. Voice Layer (Conversational Mode)**
- `ConversationalAgent.swift` - Main conversation orchestrator
- `STTManager.swift` - Speech-to-text via Apple Speech framework
- `TTSManager.swift` - Text-to-speech via AVFoundation
- `VoiceGeminiApi.swift` + `VoiceAgentModels.swift` - Intent classification LLM

Flow: User speaks → STT transcribes → Gemini classifies intent (Reply/Task/Error) → Either speaks response OR launches task agent

**2. Task Layer (Automation Mode)**
- `v3/Agent.swift` - OODA loop executor (max 100 steps)
- `v3/perception/Perception.swift` - Screen analysis via accessibility tree
- `v3/llm/GeminiApi.swift` - Action decision LLM
- `v3/actions/ActionExecutor.swift` - Executes LLM-decided actions
- `InputManager.swift` - System-level mouse/keyboard control via CGEvent
- `A11yEngine.swift` - Accessibility tree parsing

### OODA Loop (Task Execution)

Each step in `Agent.runLoop()`:
1. **SENSE**: `Perception.analyze()` captures screen via accessibility API → indexed UI elements
2. **THINK**: `MessageManager` builds context (history + screen + task) → `GeminiApi` returns `AgentOutput` (nextGoal + actions)
3. **ACT**: `ActionExecutor.execute()` performs actions via `InputManager`
4. **RECORD**: Store result in memory, increment step counter, wait 1 second

Loop continues until `done` action or 100 steps reached.

### Key Components

**Entry Point**: `metalApp.swift`
- `AppState` manages global state and hotkeys
- `HotkeyManager` - Double-tap Cmd to toggle voice, hold Fn for dictation
- `ConversationalAgent` - Voice interaction handler
- `Agent` - Task automation executor

**UI**:
- `ContentView.swift` - Main window ("Roxy" status)
- `AgentView.swift` - Task execution overlay
- `SettingsView.swift` - API key configuration
- `PermissionView.swift` - Permission request UI
- `OverlayManager.swift` - Debug overlay showing UI element indices

**System Managers**:
- `PermissionManager.swift` - Checks/requests Accessibility + Microphone permissions
- `LogManager.swift` - Structured logging system
- `AppManager.swift` - App launching via NSWorkspace

**Task System**:
- `v3/message_manager/MessageManager.swift` - Context building for LLM
- `v3/message_manager/MemoryManager.swift` - Step history management
- `v3/fs/FileSystem.swift` - Manages ~/Documents/roxy/ (todo.md, results.md, memory.txt)
- `v3/Prompts.swift` - System prompts for Gemini (macOS automation instructions)

### Available Actions

Defined in `v3/actions/Actions.swift`, executed by `ActionExecutor.swift`:

- `tap` - Click UI element by index
- `type` - Type text and press Enter
- `scroll` - Scroll up/down by pixels
- `wait` - Sleep for N seconds
- `openApp` - Launch macOS application
- `readFile` / `writeFile` / `appendFile` - File operations in ~/Documents/roxy/
- `speak` - Text-to-speech feedback
- `ask` - Show modal dialog for user input
- `done` - Mark task complete (required to exit loop)

### State Management

All classes use `@MainActor` for thread-safe UI updates:
- `AppState` - Global app state
- `ConversationalAgent` - Voice session state (@Published properties)
- `Agent` - Task execution state (AgentState)
- `AgentState` - Published state for UI binding (nSteps, currentTask, lastResult)

## Development Workflow

### File Structure

```
metal/
├── metalApp.swift          # App entry point
├── A11yEngine.swift        # Accessibility tree parser
├── A11yNode.swift          # Accessibility node model
├── InputManager.swift      # System input control (CGEvent)
├── ui/                     # SwiftUI views
│   ├── ContentView.swift
│   ├── AgentView.swift
│   ├── SettingsView.swift
│   ├── PermissionView.swift
│   └── OverlayManager.swift
├── utilities/              # Core managers
│   ├── ConfigurationManager.swift
│   ├── LogManager.swift
│   ├── PermissionManager.swift
│   ├── HotkeyManager.swift
│   ├── STTManager.swift
│   └── TTSManager.swift
├── voice/                  # Voice layer
│   ├── ConversationalAgent.swift
│   ├── VoiceGeminiApi.swift
│   └── VoiceAgentModels.swift
└── v3/                     # Task layer
    ├── Agent.swift
    ├── AgentModels.swift
    ├── Prompts.swift
    ├── AppManager.swift
    ├── perception/
    │   └── Perception.swift
    ├── llm/
    │   ├── GeminiApi.swift
    │   └── GeminiModels.swift
    ├── actions/
    │   ├── Actions.swift
    │   └── ActionExecutor.swift
    ├── message_manager/
    │   ├── MessageManager.swift
    │   ├── MemoryManager.swift
    │   ├── SystemPromptLoader.swift
    │   ├── UserMessageBuilder.swift
    │   └── HistoryItem.swift
    └── fs/
        └── FileSystem.swift
```

### Common Patterns

**Adding New Actions**:
1. Define action struct in `v3/actions/Actions.swift` (conforms to `AgentAction`)
2. Add execution logic in `ActionExecutor.execute()` switch statement
3. Update system prompt in `v3/Prompts.swift` to describe action to LLM

**Modifying LLM Behavior**:
- Task agent prompt: `v3/Prompts.swift` (`macOSSystemPrompt`)
- Voice agent prompt: `voice/VoiceGeminiApi.swift` (inline in `classifyIntent()`)
- Context building: `v3/message_manager/MessageManager.swift`

**Logging**:
```swift
LogManager.shared.info("Message")
LogManager.shared.error("Error occurred")
LogManager.shared.thinking("Analyzing...")
LogManager.shared.sensing("Reading screen...")
```

**Configuration**:
- Always use `ConfigurationManager.shared.getAPIKey(for:)` to retrieve API keys
- Never hardcode API keys in source code
- `.env` file is gitignored

## Important Notes

- **Permissions**: App cannot function without Accessibility permission. Check with `PermissionManager.shared.hasAccessibilityPermission()`
- **Hotkeys**: Double-tap Cmd (within 300ms) toggles voice mode, hold Fn for live dictation
- **Element Indexing**: UI elements in accessibility tree are indexed as `[1]`, `[2]`, `[3]` etc. for LLM reference
- **Step Limit**: Task agent has max 100 steps to prevent infinite loops (configurable in `Agent.runLoop()`)
- **File Operations**: All agent file operations occur in `~/Documents/roxy/` directory
- **Model**: Currently uses `gemini-3-flash-preview` (hardcoded in initializers)
- **Project Name Legacy**: Internal code uses "metal" namespace, but product is "Roxy"
- **API Proxy**: Original architecture used Cloud Functions proxy, now calls Gemini API directly

## Debugging

- Enable debug overlay with `OverlayManager.shared.update(elements:)` to see element indices
- Check logs via `LogManager` console output
- Task history stored in `~/Documents/roxy/memory.txt` during execution
- Use `state.nSteps` to track execution progress

## Key Dependencies

- SwiftUI (UI framework)
- AppKit (NSWorkspace for app launching)
- ApplicationServices (CGEvent for input, AXUIElement for accessibility)
- Speech (STT)
- AVFoundation (TTS)
- Security (Keychain for API key storage)
- Combine (reactive state management)
