# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains:
1. **Momentchen** - A SwiftUI-based iOS application using SwiftData for persistence
2. **BMad Framework** - A comprehensive software development methodology system with specialized AI agents and workflows

## Momentchen iOS App

### Technology Stack
- **Framework**: SwiftUI with SwiftData
- **Platform**: iOS (multiplatform support with macOS conditionals)
- **Data Layer**: SwiftData with `ModelContainer` and `ModelContext`
- **Architecture**: MVVM with SwiftUI's declarative patterns

### Project Structure
```
Momentchen/
├── Momentchen/           # Main app target
│   ├── MomentchenApp.swift       # App entry point with SwiftData setup
│   ├── ContentView.swift         # Main view with NavigationSplitView
│   ├── Item.swift                # SwiftData model
│   └── Assets.xcassets/          # App assets
└── Momentchen.xcodeproj/         # Xcode project
```

### Build and Run Commands
```bash
# Open in Xcode
open Momentchen/Momentchen.xcodeproj

# Build from command line (requires xcodebuild)
xcodebuild -project Momentchen/Momentchen.xcodeproj -scheme Momentchen -sdk iphoneos build

# Run tests (when tests are added)
xcodebuild test -project Momentchen/Momentchen.xcodeproj -scheme Momentchen -destination 'platform=iOS Simulator,name=iPhone 15'
```

### SwiftData Architecture
- **Model**: The `Item` class uses the `@Model` macro for SwiftData integration
- **Container**: Configured in `MomentchenApp.swift` with persistent storage
- **Context**: Accessed via `@Environment(\.modelContext)` in views
- **Querying**: Uses `@Query` property wrapper for reactive data fetching

### Platform-Specific Code
The app uses conditional compilation for platform-specific UI:
- `#if os(macOS)` - macOS-specific layout adjustments
- `#if os(iOS)` - iOS-specific toolbar items

## BMad Method Framework

The BMad Method Module (BMM) is an agent-based software development orchestration system located in the `bmad/` directory.

### BMad Structure
```
bmad/
├── core/                  # Core system components
│   ├── agents/           # Agent definitions (bmad-master, etc.)
│   ├── workflows/        # Core workflows (brainstorming, party-mode)
│   ├── tasks/            # Reusable task definitions
│   └── config.yaml       # User configuration (name, language, output_folder)
├── bmm/                  # BMad Method Module
│   ├── agents/           # Specialized development agents (PM, Architect, SM, DEV, TEA, UX)
│   ├── workflows/        # 4-phase development workflows
│   │   ├── 1-analysis/   # Optional: brainstorming, research, product briefs
│   │   ├── 2-plan-workflows/  # Required: PRD, GDD, project planning
│   │   ├── 3-solutioning/     # Level 3-4: architecture, tech specs
│   │   └── 4-implementation/  # Iterative: story creation and execution
│   ├── teams/            # Pre-configured agent teams
│   ├── tasks/            # BMM-specific task library
│   └── testarch/         # Test architecture framework (TEA workflows)
└── _cfg/                 # Agent customization configs
```

### BMad Workflow Phases

BMM follows a 4-phase methodology that adapts to project scale (Level 0-4):

**Phase 1: Analysis** (Optional)
- Brainstorming, market research, product/game briefs
- Entry workflows: `brainstorm-project`, `brainstorm-game`, `research`, `product-brief`, `game-brief`

**Phase 2: Planning** (Required)
- Scale-adaptive routing based on project complexity
- Software projects: `plan-project` → Level 0-1: tech-spec only, Level 2: PRD, Level 3-4: PRD + Epics
- Game projects: `gdd` → Game Design Document + narrative design

**Phase 3: Solutioning** (Level 3-4 only)
- Architecture design via `3-solutioning` workflow
- Just-In-Time technical specifications created per epic during implementation

**Phase 4: Implementation** (Iterative)
- Story lifecycle: `create-story` → `story-ready` → `story-context` → `dev-story` → `review-story` → `story-done`
- Continuous improvement: `retrospective`, `correct-course`

### Scale Levels
- **Level 0**: Single atomic change, tech-spec only
- **Level 1**: 1-10 stories, minimal documentation
- **Level 2**: 5-15 stories, focused PRD
- **Level 3**: 12-40 stories, full architecture + PRD
- **Level 4**: 40+ stories, enterprise scale

### Specialized Agents

BMad provides role-based agents accessed via slash commands:
- `/bmad:bmm:agents:pm` - Product Manager (planning, requirements)
- `/bmad:bmm:agents:analyst` - Business Analyst (research, analysis)
- `/bmad:bmm:agents:architect` - Technical Architect (design, architecture)
- `/bmad:bmm:agents:sm` - Scrum Master (sprint, story management)
- `/bmad:bmm:agents:dev` - Developer (implementation)
- `/bmad:bmm:agents:tea` - Test Architect (testing strategy, quality gates)
- `/bmad:bmm:agents:ux-expert` - UX Designer (user experience)
- `/bmad:bmm:agents:game-designer` - Game Designer
- `/bmad:bmm:agents:game-architect` - Game Architect
- `/bmad:core:agents:bmad-master` - Master orchestrator and workflow coordinator

### Test Architecture (TEA)

The Test Architect provides 9 comprehensive workflows:
- `framework` - Test framework setup
- `ci` - CI/CD integration
- `test-design` - Test strategy and design
- `atdd` - Acceptance Test-Driven Development
- `automate` - Test automation
- `trace` - Requirements traceability
- `nfr-assess` - Non-functional requirements assessment
- `test-review` - Quality gate reviews

Knowledge base includes patterns for:
- Component TDD, contract testing, data factories
- Playwright configuration, selector resilience, test healing
- Feature flags, error handling, timing debugging
- Risk governance, test priorities matrix

### Key BMad Concepts

**Story State Machine**:
```
BACKLOG → TODO → IN PROGRESS → DONE
```
Tracked in workflow status file, never search for "next story" - always read from status.

**Dynamic Expertise Injection**: The `story-context` workflow provides targeted technical guidance per story, replacing static documentation with contextual expertise.

**Just-In-Time Design**: Technical specs created one epic at a time during implementation, allowing for learning and adaptation.

### BMad Configuration

Configuration lives in `bmad/core/config.yaml`:
```yaml
project_name: string
output_folder: string
user_name: string
communication_language: string  # e.g., "English", "Deutsch"
```

Agent customizations in `bmad/_cfg/agents/*.customize.yaml` allow persona and behavior modifications.

## Development Workflows

### Adding Features to Momentchen
1. Define models in SwiftData using `@Model` macro
2. Register models in `MomentchenApp.swift` Schema
3. Create views using SwiftUI declarative syntax
4. Access data via `@Query` or modelContext operations
5. Use conditional compilation for platform-specific UI

### Using BMad Workflows
1. Start with `/bmad:core:agents:bmad-master` to access the orchestrator
2. Load `bmad/core/config.yaml` to configure user preferences
3. Execute workflows through the master agent menu system
4. Follow phase progression: Analysis → Planning → Solutioning → Implementation
5. Use specialized agents via slash commands for specific tasks

### Working with SwiftData
```swift
// Define model
@Model
final class YourModel {
    var property: Type
    init(property: Type) { self.property = property }
}

// Register in schema (MomentchenApp.swift)
let schema = Schema([Item.self, YourModel.self])

// Query in views
@Query private var items: [YourModel]

// Mutations via context
@Environment(\.modelContext) private var modelContext
modelContext.insert(newItem)
modelContext.delete(item)
```

## Important Notes

- The Momentchen app is a minimal SwiftUI starter with SwiftData persistence
- BMad framework is a complete methodology system - agents have specific personas and follow strict activation protocols
- When working with BMad agents, always load `bmad/core/config.yaml` first to access user preferences
- BMad workflows output to the configured `output_folder` from config.yaml
- Test Architecture (TEA) workflows are comprehensive - refer to `bmad/bmm/testarch/README.md` for detailed guidance
- BMad agents communicate in the language specified in config.yaml (`communication_language`)
