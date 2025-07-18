# Gemini AI Workspace Configuration

## Development Mandates

### 1. Single Source of Truth
- **Primary Specification**: The root file `推荐系统完整流程规范.md` is the **sole and absolute source of truth** for all system architecture, API contracts, data flows, and database schemas.
- **Mandatory Adherence**: All development, verification, and modifications must strictly adhere to this document. Any deviation must be discussed and, if approved, immediately updated in this specification.

### 2. Code Modification Boundaries
- **Java Backend (Frozen)**: **STRICTLY FORBIDDEN** to modify any Java code within the `Recommendation` module (`/Recommendation/src/main/java/org/recommendation/`). The Java backend is considered stable and complete.
- **Python Module (Modifiable)**: **ALLOWED** to modify the Python code within the `Rec_LLM_Module` (`/Recommendation/src/main/java/org/recommendation/Rec_LLM_Module/`) to improve algorithms, enhance data processing, or fix bugs, provided the changes align with the primary specification.

### 3. Real-World Operations Only
- **NO MOCKING**: All forms of data or service mocking are **strictly forbidden**. Development and testing must use real database connections and live external API calls (e.g., OpenAI).
- **NO LOCAL FALLBACKS**: All forms of local fallback or degradation strategies (e.g., providing a default response when an LLM call fails) are **strictly forbidden**. The system must be robust enough to handle real-world service failures without resorting to simulated or degraded functionality.

## State and Task Management Protocol

This protocol ensures seamless context transfer, progress tracking, and clarity between sessions and agents.

### **Interaction Lifecycle Mandate (CRITICAL)**
- **SESSION START**: The **FIRST ACTION** in any new interaction MUST be to read the content of `session-handoff.md` and `todo.md` to gain full and current project context.
- **SESSION END**: The **LAST ACTION** of any interaction MUST be to update `session-handoff.md` and `todo.md` to reflect all work completed and the current project state.
- **STRICT COMPLIANCE**: This is not a suggestion, but a mandatory operational step to ensure continuity.

### 1. Proactive Design Clarification
- **Mandate**: When faced with ambiguity or underspecified requirements regarding feature design, architecture, or implementation logic, the agent **must** proactively ask the user systematic and guiding questions.
- **Goal**: To elicit clear, actionable requirements *before* proceeding with implementation, preventing rework and ensuring alignment with the user's vision.

### 2. `session-handoff.md`: The State Log
- **Purpose**: To document the **current state** of the project and log **significant, consolidated modifications** made during a session. It is a high-level state summary, not a verbose commit log.
- **Update Cadence**: Must be updated at the end of every session/interaction.
- **Update Method**:
    - **Read First**: Always read the existing file before writing.
    - **Consolidate, Don't Just Append**: Review previous entries. If a new change modifies or supersedes an old one, **update the existing entry**. For example, if you first add a function and later refactor it, the final entry should only describe the refactored state.
    - **Focus on "What" and "Why"**: Log what the state of a feature is now and why the key changes were made.
    - **Brevity and Clarity**: Keep the log concise and easy to understand.

### 3. `todo.md`: The Action Plan
- **Purpose**: To maintain a clear, simple, and precise checklist of project tasks. It serves as the primary progress tracking tool.
- **Update Cadence**: Must be updated at the end of every session/interaction, in sync with `session-handoff.md`.
- **Format**: Use markdown checkboxes to track status.
    - `[ ]` - To Do
    - `[x]` - Done
    - `[/]` - In Progress (Optional)
- **Content**: Tasks should be broken down into actionable and verifiable steps.

### 4. Synergy
- `session-handoff.md` describes the **past and present** (what was done, what is the current state).
- `todo.md` describes the **future** (what needs to be done next).
- Both files must be read at the start of a session to gain full context.

## MVP Development Philosophy

### Core Principles
- **NO MOCK**: Never use mocks or stubs except for database connections
- **NO DEGRADATION**: Never accept reduced functionality or workarounds
- **REAL END-TO-END**: All tests and development must use real services and integrations
- **SOLVE PROBLEMS**: When encountering issues, solve them rather than working around them
- **PRODUCTION-READY**: All code must be production-ready from day one

### Development Standards
- **REAL DATABASES**: Use actual database connections and real data
- **REAL APIS**: Connect to actual external services (OpenAI, etc.)
- **REAL INTEGRATION**: Test complete request flows through all system layers
- **REAL CONFIGURATION**: Use production-like configuration and environment setup
- **REAL ERROR HANDLING**: Handle actual errors, not simulated ones

### Scope Control Principles
- **MINIMAL CHANGES**: Make the smallest possible changes to achieve the goal
- **ISOLATED IMPACT**: Ensure changes don't cascade to unrelated components
- **EXPLICIT PERMISSION**: Never modify APIs or frontend-backend contracts without explicit instruction
- **CONTAINED MODIFICATIONS**: Keep all changes within the specified functional scope
- **RISK MITIGATION**: Prevent problem escalation through controlled change scope

## Workspace Constraints

### Primary Work Area
- **RESTRICTED TO**: `/Recommendation/` module only
- **FORBIDDEN**: Modifications to other modules (Backend, Product, User, Allergen, OCR, Common)
- **SCOPE**: All work must be contained within the Recommendation module boundary
- **FRONTEND INTEGRATION**: Limited to frontend components that integrate with recommendation system functionality

### Recommendation Module Structure
```
Recommendation/
├── src/main/java/org/recommendation/
│   ├── App.java
│   ├── Rec_LLM_Module/          # Python-based LLM integration
│   ├── controller/              # Java REST controllers
│   ├── pojo/                    # Data objects
│   ├── repository/              # Data access layer
│   └── service/                 # Business logic
└── src/test/                    # Unit tests
```

## SATO Standards Compliance

### Security (S)
- **NO** hardcoded credentials or API keys
- **NO** exposure of sensitive data in logs
- **VALIDATE** all input parameters
- **SANITIZE** all database queries
- **ENCRYPT** sensitive data transmission

### Availability (A)
- **IMPLEMENT** proper error handling with meaningful messages
- **ENSURE** graceful degradation on service failures
- **MAINTAIN** connection pooling for database operations
- **PROVIDE** health check endpoints

### Testability (T)
- **WRITE** comprehensive end-to-end tests for all business logic
- **NO MOCKING**: Use real external dependencies and services
- **MAINTAIN** test coverage above 80% with real integration tests
- **ENSURE** tests verify actual system behavior in real conditions

### Observability (O)
- **LOG** all significant operations with appropriate levels
- **INSTRUMENT** performance metrics
- **TRACE** request flows through the system
- **MONITOR** system health and performance

## Work Boundaries

### Allowed Operations
- Modify files within `/Recommendation/` module
- Add new Java classes in recommendation package
- Update Python modules in `Rec_LLM_Module/`
- Create/modify tests in recommendation test package
- Update recommendation-specific configuration
- **FRONTEND INTEGRATION**: Modify frontend components that directly integrate with recommendation system
- **SCAN PAGE INTEGRATION**: Update scan results display to show AI-generated recommendations
- **RECOMMENDATION DETAIL PAGES**: Create/modify pages for detailed LLM feedback presentation

### Forbidden Operations
- Cross-module dependencies outside recommendation
- Database schema changes affecting other modules
- Modification of shared common utilities
- Changes to global configuration files
- Direct access to other modules' internal APIs
- **API CONTRACT CHANGES**: Modifying REST API endpoints, request/response formats, or HTTP methods
- **FRONTEND-BACKEND INTERFACE CHANGES**: Altering any communication contracts between frontend and backend
- **EXTERNAL API MODIFICATIONS**: Changing external service integration interfaces
- **BREAKING CHANGES**: Any modifications that could break existing functionality

## Session Handoff Requirements

### Dynamic State Synchronization
- **MANDATORY**: Always read and update `session-handoff.md` at the start and end of each session
- **MANDATORY**: Maintain real-time synchronization with Claude Code through shared handoff file
- **MANDATORY**: Document current project state and key modifications immediately after completion

### Handoff Protocol Implementation
1. **Session Start**:
   - Read `session-handoff.md` for current project status
   - Update session information (current session, start time, status)
   - Review pending tasks and work in progress
   - Verify environment and git status

2. **During Session**:
   - Update current state for each significant change
   - Document key modifications with file paths and line numbers
   - Note any issues, blockers, or discoveries
   - Maintain compatibility with workspace boundary constraints

3. **Session End**:
   - Update final state for all components worked on
   - Document next session priorities
   - Update testing status and known issues
   - Prepare concise handoff notes for next developer (Claude or Gemini)

### Handoff File Maintenance
- **Location**: `/session-handoff.md` (project root)
- **Format**: Structured markdown with clear sections
- **Update Frequency**: Real-time during active development
- **Synchronization**: Both Claude and Gemini must maintain this file
- **Content**: Current system state, key modifications, pending work, testing status
- **Purpose**: **STATE TRACKING** - Document current project state and critical changes, not achievement records
- **Logic**: Update to reflect latest state, consolidate repeated modifications, remove obsolete changes

### Cross-AI Collaboration
- **Shared Responsibility**: Both Claude Code and Gemini CLI maintain the handoff file
- **Conflict Resolution**: Later timestamp takes precedence
- **Communication**: Use handoff file as primary communication channel
- **Consistency**: Maintain consistent format and structure across sessions
- **Efficiency**: Consolidate related changes, avoid redundant documentation

### Emergency Procedures
- **Rollback Information**: Always include rollback instructions in handoff file
- **Critical Issues**: Document immediately with severity level
- **Handoff Failures**: Include contact information and alternative procedures

### Compliance Requirements
- Reference `session-handoff.md` for context transfer protocols
- Maintain state consistency across session boundaries
- Document all pending changes and incomplete work
- Preserve workspace boundary constraints
- **CONSOLIDATED UPDATES**: Ensure handoff file reflects current state efficiently, avoiding excessive detail

## Code Quality Standards
- Follow existing Java coding conventions
- Maintain consistent Python style in LLM modules
- Use dependency injection for real service integration
- Implement comprehensive error handling for real-world scenarios
- Document public APIs and complex logic
- **NO SHORTCUTS**: Build production-ready, fully functional code
- **SOLVE ROOT CAUSES**: Fix underlying issues rather than applying patches

## Integration Points
- **Database**: Use existing JPA repositories with real database connections
- **External APIs**: Direct integration with actual external services
- **LLM Integration**: Real OpenAI API calls via Python module bridge
- **Logging**: Comprehensive logging for real-world debugging
- **Monitoring**: Real-time metrics collection and performance monitoring
- **Frontend Integration**: Seamless integration between recommendation backend and frontend components
- **Scan Page Integration**: Display concise AI analysis results directly on scan results page
- **Detail Page Integration**: Provide detailed LLM feedback through dedicated recommendation detail pages

### Frontend Development Environment
- **CRITICAL**: Frontend code changes MUST be manually saved before running `flutter run -d chrome`
- **AUTO-SAVE DELAY**: The development environment has auto-save enabled but with noticeable delay
- **MANDATORY WORKFLOW**: Always save all modified files before restarting Flutter application
- **HOT RELOAD LIMITATION**: Code changes will NOT appear without explicit save operation or waiting for auto-save delay

## Problem-Solving Approach
- **INVESTIGATE**: Thoroughly analyze issues before proposing solutions
- **DEBUG**: Use real debugging techniques on actual systems
- **FIX**: Implement permanent solutions, not temporary workarounds
- **VERIFY**: Test fixes in real environments with actual data
- **DOCUMENT**: Record solutions for future reference and team learning

## Change Control Protocol

### Before Making Any Changes
1. **ASSESS SCOPE**: Identify all components that could be affected
2. **VERIFY BOUNDARIES**: Ensure changes stay within allowed modification areas
3. **CHECK CONTRACTS**: Confirm no API or interface changes are required
4. **SEEK PERMISSION**: Ask for explicit approval before modifying:
   - REST API endpoints or HTTP methods
   - Request/response JSON structures
   - Frontend-backend communication protocols
   - External service integration contracts

### During Implementation
- **INCREMENTAL CHANGES**: Make small, testable modifications
- **IMMEDIATE TESTING**: Verify each change doesn't break existing functionality
- **ROLLBACK READY**: Maintain ability to quickly revert changes
- **IMPACT MONITORING**: Watch for unexpected side effects

### Change Approval Required For
- **API Endpoint Modifications**: Adding, removing, or changing REST endpoints
- **Request/Response Changes**: Modifying JSON structures or data formats
- **HTTP Method Changes**: Altering GET, POST, PUT, DELETE operations
- **Authentication/Authorization Changes**: Modifying security protocols
- **Cross-Module Integration**: Changes affecting other system modules