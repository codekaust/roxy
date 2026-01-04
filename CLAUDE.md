# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Metal is a macOS desktop automation agent built with Swift/SwiftUI. It uses voice commands, screen perception via accessibility APIs, and Google Gemini LLM to autonomously control macOS applications. The UI is branded as "Panda Agent".

## Build Commands

```bash
# Build the project
xcodebuild -project metal.xcodeproj -scheme metal -configuration Debug build

# Run tests
xcodebuild -project metal.xcodeproj -scheme metal test

# Clean build
xcodebuild -project metal.xcodeproj -scheme metal clean
```

Open `metal.xcodeproj` in Xcode for development with full IDE support (build: Cmd+B, run: Cmd+R).

## Architecture

### Core Agent Loop (`v3/Agent.swift`)
Implements OODA (Observe-Orient-Decide-Act) pattern:
1. **SENSE**: Capture screen state via accessibility tree
2. **THINK**: Build context → call Gemini LLM
3. **ACT**: Execute returned actions (tap, type, scroll, etc.)
4. **LOOP**: Record results in memory, repeat until done

### Key Components

- **`metalApp.swift`** - Entry point, `AppState` manages voice agent, hotkeys, and STT
- **`v3/`** - Core agent framework
  - `Agent.swift` - Main reasoning loop with step tracking
  - `llm/GeminiApi.swift` - Gemini API client (proxied through Cloud Function)
  - `actions/Actions.swift` - Action enum with payloads (tap, type, scroll, file ops, etc.)
  - `perception/Perception.swift` - Accessibility tree parsing, element indexing
  - `message_manager/` - LLM context building (memory, system prompts, user messages)
- **`voice/ConversationalAgent.swift`** - Voice session manager with silence detection
- **`InputManager.swift`** - System-level mouse/keyboard control via ApplicationServices
- **`A11yEngine.swift`** - Accessibility API tree builder
- **`ui/`** - SwiftUI views (AgentView, SettingsView, OverlayManager for debug visualization)
- **`utilities/`** - HotkeyManager (Cmd double-tap, Fn key), STTManager, TTSManager

### Data Flow

```
Voice/Text Input → ConversationalAgent → Agent Loop → Gemini API
                                              ↓
Screen Perception ← Accessibility Tree ← Active App
                                              ↓
                                      ActionExecutor → InputManager → macOS
```

### File System

Agent uses `~/Documents/` for persistent files:
- `todo.md` - Task tracking
- `results.md` - Action results
- `memory.txt` - Agent memory

## External Dependencies

- **Google Gemini API** via Cloud Function proxy (`us-central1-panda-465116.cloudfunctions.net`)
- **Apple Frameworks** (native): Speech, AppKit, ApplicationServices, AVFoundation

No SPM/CocoaPods dependencies - pure native Swift.

## Runtime Requirements

- macOS with Accessibility permission granted (System Preferences → Privacy & Security → Accessibility)
- Microphone permission for voice features

## Notes

- API key is hardcoded in `GeminiApi.swift:33` - handle with care
- Hotkeys: Command double-tap and Fn key for voice activation
- Debug overlay shows red boxes around detected UI elements
