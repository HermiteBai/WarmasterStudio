# Warmaster Studio — Development Work Plan (v1.1)

> Based on Product Requirements Document v1.4
> Platform: macOS 14 Sonoma+, SwiftUI, SwiftData, zero third-party dependencies

---

## 1. How to Use This Plan

This work plan breaks the Warmaster Studio project into granular, independently completable development tasks. Each task is sized for **one focused coding session (1–4 hours)** and scopes exactly one concern — a single model, a single view, a single behaviour.

**Task ID format:** `P{phase}-{category abbreviation}-{sequence number}`
For example, `P1-DM-03` is Phase 1, Data Model, task 03.

**Workflow recommendation:**
1. Work top-to-bottom within each phase. Dependencies are listed explicitly so you can parallelise where possible.
2. Mark the **Status** column in the summary table as work progresses (`Todo` → `In Progress` → `Done`).
3. Complete all Phase 1 tasks (and their tests) before beginning Phase 2.
4. Phase 3 tasks are defined below.

**Category abbreviations used in this plan:**

| Abbr. | Category |
|---|---|
| DM | Data Model |
| AS | App Shell |
| PC | Feature: Pipeline Config |
| COL | Feature: Collections |
| PRJ | Feature: Projects |
| KB | Feature: Kanban |
| DASH | Feature: Progress Dashboard |
| IMG | Feature: Box Art Images |
| PIN | Feature: Recipe Pins |
| REC | Feature: Paint Recipes |
| PLT | Feature: Paint Library |
| LIB | Feature: Image Library |
| TEST | Testing |
| POL | Polish |

---

## 2. Summary Table

### Phase 1 — MVP

| Task ID | Title | Category | Est. Hours | Status |
|---|---|---|---|---|
| P1-AS-01 | Xcode project scaffold & deployment target | App Shell | 1 | Done |
| P1-AS-02 | SwiftData ModelContainer setup & environment injection | App Shell | 2 | Done |
| P1-AS-03 | NavigationSplitView shell (sidebar + detail area) | App Shell | 2 | Done |
| P1-AS-04 | Settings window (⌘,) scaffold | App Shell | 1 | Done |
| P1-AS-05 | Global toolbar & keyboard shortcut infrastructure | App Shell | 2 | Done |
| P1-DM-01 | `Pipeline` @Model — singleton design & fields | Data Model | 2 | Done |
| P1-DM-02 | `Stage` @Model — fields, ordering, relationships | Data Model | 2 | Done |
| P1-DM-03 | `Project` @Model — fields & relationships | Data Model | 2 | Done |
| P1-DM-04 | `ModelRecord` @Model — fields & relationship to Project | Data Model | 1 | Done |
| P1-DM-05 | `Collection` @Model — fields & project relationship | Data Model | 1 | Done |
| P1-DM-06 | Pipeline singleton bootstrap & default-stage seeding | Data Model | 2 | Done |
| P1-PC-01 | Pipeline config view — stage list display | Feature: Pipeline Config | 2 | Done |
| P1-PC-02 | Add & rename stage | Feature: Pipeline Config | 2 | Done |
| P1-PC-03 | Reorder stages via drag | Feature: Pipeline Config | 2 | Done |
| P1-PC-04 | Delete stage with guard (blocked if models present) | Feature: Pipeline Config | 2 | Done |
| P1-COL-01 | Collection list sidebar section | Feature: Collections | 1 | Done |
| P1-COL-02 | Create & rename collection | Feature: Collections | 2 | Done |
| P1-COL-03 | Delete collection (unlink projects gracefully) | Feature: Collections | 2 | Done |
| P1-PRJ-01 | Project creation form (name, count, collection, notes, linkGroupId) | Feature: Projects | 3 | Done |
| P1-PRJ-02 | ModelRecord auto-generation on project creation | Feature: Projects | 2 | Done |
| P1-PRJ-03 | Project detail view (metadata, model list) | Feature: Projects | 2 | Done |
| P1-PRJ-04 | Project edit & delete | Feature: Projects | 2 | Done |
| P1-KB-01 | Kanban board layout (horizontal scroll, per-stage columns) | Feature: Kanban | 3 | Done |
| P1-KB-02 | Kanban column view (header + card list) | Feature: Kanban | 2 | Done |
| P1-KB-03 | Project-stage card view (title, stage model count, progress) | Feature: Kanban | 2 | Done |
| P1-KB-04 | Card lifecycle — appear/disappear as models enter/leave a stage | Feature: Kanban | 2 | Done |
| P1-KB-05 | +/− model buttons on card (move one model at a time) | Feature: Kanban | 2 | Done |
| P1-KB-06 | Drag-and-drop card (move all models to target stage) | Feature: Kanban | 3 | Done |
| P1-KB-07 | Linked project grouping (shared `linkGroupId` visual treatment) | Feature: Kanban | 2 | Done |
| P1-DASH-01 | Dashboard view layout & navigation entry point | Feature: Progress Dashboard | 2 | Done |
| P1-DASH-02 | Per-stage unit count and model count aggregation | Feature: Progress Dashboard | 2 | Done |
| P1-DASH-03 | Collection filter for dashboard | Feature: Progress Dashboard | 2 | Done |
| P1-TEST-01 | Unit tests — Pipeline singleton & stage ordering logic | Testing | 2 | Done |
| P1-TEST-02 | Unit tests — model count transitions & stage guard logic | Testing | 2 | Done |
| P1-TEST-03 | UI smoke tests — Kanban board (column count, card presence) | Testing | 3 | Done |
| P1-POL-01 | Empty states for Kanban, Dashboard, Collections, and Projects | Polish | 2 | Done |
| P1-POL-02 | Accessibility labels and VoiceOver support (Phase 1 views) | Polish | 3 | Done |

**Phase 1 total: 37 tasks, ~73 estimated hours**

---

### Phase 2 — Box Art, Recipes & Paint Library

| Task ID | Title | Category | Est. Hours | Status |
|---|---|---|---|---|
| P2-IMG-01 | `imageExternalURL` and sandbox-local path fields on `Project` | Feature: Box Art Images | 2 | Done |
| P2-IMG-02 | Image import UI — file picker, Security-scoped bookmark, sandbox copy | Feature: Box Art Images | 3 | Done |
| P2-IMG-03 | Image display view inside Project detail | Feature: Box Art Images | 2 | Done |
| P2-IMG-04 | Relative path persistence and bookmark resolution on relaunch | Feature: Box Art Images | 2 | Done |
| P2-IMG-05 | Shared box art across linked projects (link-group sync) | Feature: Box Art Images | 1 | Done |
| P2-PIN-01 | `RecipePin` @Model — normalised coordinates & recipe reference | Feature: Recipe Pins | 2 | Done |
| P2-PIN-02 | Pin placement UI — click/tap on image to place pin | Feature: Recipe Pins | 3 | Done |
| P2-PIN-03 | Pin popover — display linked recipe name and first step | Feature: Recipe Pins | 2 | Done |
| P2-PIN-04 | Pin drag to reposition on image | Feature: Recipe Pins | 2 | Done |
| P2-PIN-05 | Pin delete | Feature: Recipe Pins | 1 | Done |
| P2-REC-01 | `PaintRecipe` @Model — name, ordered steps, project relationship | Feature: Paint Recipes | 2 | Done |
| P2-REC-02 | `RecipeStep` @Model & `Technique` enum | Feature: Paint Recipes | 2 | Done |
| P2-REC-03 | Recipe library list view | Feature: Paint Recipes | 2 | Done |
| P2-REC-04 | Recipe creation form (name, add steps) | Feature: Paint Recipes | 2 | Done |
| P2-REC-05 | Step editor (paint picker, technique selector, notes) | Feature: Paint Recipes | 3 | Done |
| P2-REC-06 | Step reordering within recipe | Feature: Paint Recipes | 2 | Done |
| P2-REC-07 | Recipe edit & delete | Feature: Paint Recipes | 1 | Done |
| P2-PLT-01 | `Paint` @Model — fields (name, brand, hex, isUserAdded) | Feature: Paint Library | 2 | Done |
| P2-PLT-02 | JSON catalogue seed file and on-launch import (read-only paints) | Feature: Paint Library | 3 | Done |
| P2-PLT-03 | My Paints CRUD (add, edit, delete user-defined paints) | Feature: Paint Library | 2 | Done |
| P2-PLT-04 | Colour swatch rendering from hex string (`Color(hex:)` extension) | Feature: Paint Library | 1 | Done |
| P2-PLT-05 | Unified paint search view (catalogue + My Paints, filterable by brand) | Feature: Paint Library | 3 | Done |
| P2-TEST-01 | Unit tests — recipe step ordering and technique enum coverage | Testing | 2 | Done |
| P2-TEST-02 | Unit tests — paint catalogue seeding (no duplicates, correct count) | Testing | 2 | Done |
| P2-TEST-03 | Unit tests — pin coordinate clamping and normalisation | Testing | 2 | Done |
| P2-TEST-04 | UI tests — image attach, place pin, link recipe end-to-end | Testing | 3 | Done |
| P2-POL-01 | Empty states for Recipe library and Paint library | Polish | 1 | Done |
| P2-POL-02 | Accessibility labels for image canvas, pins, and swatches | Polish | 2 | Done |

| P2-LIB-01 | `ImageLibraryService` — scan Application Support folder, emit `LibraryImage` list | Feature: Image Library | 2 | Done |
| P2-LIB-02 | Image Library sidebar entry and game system selector | Feature: Image Library | 1 | Done |
| P2-LIB-03 | Faction chip filter strip with `WrapLayout` (multi-row, narrow-window safe) | Feature: Image Library | 2 | Done |
| P2-LIB-04 | Image grid view with `LazyVGrid` thumbnails | Feature: Image Library | 2 | Done |
| P2-LIB-05 | Lightbox overlay viewer with prev/next navigation (click-outside to dismiss) | Feature: Image Library | 2 | Done |
| P2-LIB-06 | Move to Faction — right-click context menu, file move, grid refresh | Feature: Image Library | 2 | Done |
| P2-LIB-07 | Create Project from Image sheet (auto-fill name, collection, box art; editable model count) | Feature: Image Library | 3 | Done |

**Phase 2 total: 34 tasks, ~71 estimated hours**

---

---

### Phase 3 — Platform Expansion

#### Statistics (P3-STAT)

| Task ID | Title | Category | Est. Hours | Status |
|---|---|---|---|---|
| P3-STAT-01 | `StageHistoryEntry` @Model — stageId, enteredAt, leftAt | Data Model | 2 | In Progress |
| P3-STAT-02 | Record stage-entry/exit timestamps in ModelProgressService | Data Model | 2 | In Progress |
| P3-STAT-03 | `VelocityService` — avg time per stage, completion rate, projected finish | Feature: Statistics | 3 | In Progress |
| P3-STAT-04 | Statistics view — per-stage avg time, velocity chart, projected date | Feature: Statistics | 4 | In Progress |
| P3-STAT-05 | Collection filter on statistics view | Feature: Statistics | 1 | In Progress |
| P3-STAT-06 | Unit tests for VelocityService | Testing | 2 | In Progress |

#### CloudKit Sync (P3-CK)

| Task ID | Title | Category | Est. Hours | Status |
|---|---|---|---|---|
| P3-CK-01 | Audit @Model types for CloudKit constraints (optional rels, no cycles) | CloudKit Sync | 2 | Todo |
| P3-CK-02 | Update ModelContainer configuration for CloudKit compatibility | CloudKit Sync | 2 | Todo |
| P3-CK-03 | Add CloudKit entitlement and container ID | CloudKit Sync | 1 | Todo |
| P3-CK-04 | Graceful sync-error handling in UI | CloudKit Sync | 2 | Todo |

#### iOS Companion (P3-iOS)

| Task ID | Title | Category | Est. Hours | Status |
|---|---|---|---|---|
| P3-iOS-01 | Add iOS target; shared WarmasterStudioKit compiles for iOS | iOS Companion | 3 | Todo |
| P3-iOS-02 | iOS navigation shell (TabView: Kanban, Collections, Recipes, Paints) | iOS Companion | 3 | Todo |
| P3-iOS-03 | Adaptive KanbanCard and board view for compact width | iOS Companion | 3 | Todo |
| P3-iOS-04 | iOS project detail (read + stage navigation) | iOS Companion | 2 | Todo |
| P3-iOS-05 | iOS paint library view (browse + filter) | iOS Companion | 2 | Todo |

**Phase 3 total: 15 tasks, ~32 estimated hours**

---

**Grand total: 86 tasks, ~176 estimated hours**

---

## 3. Detailed Task Descriptions

---

### Phase 1 — MVP

---

#### App Shell

---

##### P1-AS-01 · Xcode Project Scaffold & Deployment Target

**Description:** Create the Xcode project from scratch using the macOS App template. Set the deployment target to macOS 14.0. Configure bundle ID, app name (`Warmaster Studio`), and code-signing (development team). Add the `NSSupportsAutomaticGraphicsSwitching` and any required entitlements to the entitlements file. Confirm the project builds and runs to a blank window on macOS 14 Sonoma.

**Key files/types to create or modify:**
- `WarmasterStudio.xcodeproj`
- `WarmasterStudio.entitlements`
- `Info.plist` (or `Info.xcconfig`)
- `WarmasterStudioApp.swift` (entry point)

**Dependencies:** none

**Estimated hours:** 1

---

##### P1-AS-02 · SwiftData ModelContainer Setup & Environment Injection

**Description:** Configure the `ModelContainer` with all Phase 1 schema types. Inject it into the SwiftUI environment in `WarmasterStudioApp`. Use `modelContainer(for:)` with the full schema list. Verify that the container initialises without schema errors and that a simple `@Query` fetch works in a test view. Define the schema version struct for future migrations.

**Key files/types to create or modify:**
- `WarmasterStudioApp.swift`
- `AppSchema.swift` (version enum + `Schema` definition)

**Dependencies:** P1-AS-01, P1-DM-01 through P1-DM-05

**Estimated hours:** 2

---

##### P1-AS-03 · NavigationSplitView Shell (Sidebar + Detail Area)

**Description:** Implement the top-level `ContentView` using `NavigationSplitView` with a sidebar and detail column. The sidebar lists the main destinations: **Kanban** (home), **Dashboard**, **Collections**, and **Pipeline Settings** (or Settings window entry). The detail area shows the selected destination's root view. Navigation selection state is managed with an enum. Confirm basic navigation between destinations works.

**Key files/types to create or modify:**
- `ContentView.swift`
- `SidebarView.swift`
- `AppDestination.swift` (navigation enum)

**Dependencies:** P1-AS-01

**Estimated hours:** 2

---

##### P1-AS-04 · Settings Window (⌘,) Scaffold

**Description:** Register a `Settings` scene in the app entry point (`WindowGroup` + `Settings`). The Settings window opens on ⌘, and contains at minimum a placeholder `PipelineSettingsView` tab. Use `TabView` with labelled tabs so additional settings tabs can be added later. Verify ⌘, opens the window and the keyboard shortcut is system-registered.

**Key files/types to create or modify:**
- `WarmasterStudioApp.swift`
- `SettingsView.swift`

**Dependencies:** P1-AS-01

**Estimated hours:** 1

---

##### P1-AS-05 · Global Toolbar & Keyboard Shortcut Infrastructure

**Description:** Define a reusable toolbar extension / toolbar builder pattern so each view can declare its own toolbar items without coupling to `ContentView`. Register app-level keyboard shortcuts: ⌘N (new project), ⌘, (settings — already handled by macOS), and ⌘R (refresh/reload). Use `.keyboardShortcut` modifiers and `@FocusedValue` or `@FocusedBinding` where commands need to reach the active view. Document the shortcut registry in a `KeyboardShortcuts.swift` constants file.

**Key files/types to create or modify:**
- `KeyboardShortcuts.swift`
- `ContentView.swift` (toolbar slots)

**Dependencies:** P1-AS-03

**Estimated hours:** 2

---

#### Data Model

---

##### P1-DM-01 · `Pipeline` @Model — Singleton Design & Fields

**Description:** Create the `Pipeline` SwiftData model. It is a global singleton (only one row should ever exist). Fields: `id: UUID`, `createdAt: Date`. Relationships: `stages: [Stage]` (ordered, cascade delete). Add a static `fetch()` convenience that either returns the existing instance or creates and inserts it. Document why only one `Pipeline` should exist and how the singleton guarantee is enforced at the fetch layer.

**Key files/types to create or modify:**
- `Models/Pipeline.swift`

**Dependencies:** P1-AS-01

**Estimated hours:** 2

---

##### P1-DM-02 · `Stage` @Model — Fields, Ordering, Relationships

**Description:** Create the `Stage` SwiftData model. Fields: `id: UUID`, `name: String`, `sortIndex: Int`. Relationship: `pipeline: Pipeline` (inverse). Relationship: `modelRecords: [ModelRecord]` (inverse, no cascade — ModelRecords outlive stage deletion). Include a computed property `displayName: String` (trimmed). Ensure `sortIndex` uniqueness is maintained at the data layer by always assigning `max(existing sortIndex) + 1` on creation. Add a static helper `defaultStages() -> [Stage]` returning `["Shelf", "Assembly", "Priming", "Painting", "Basing", "Done"]`.

**Key files/types to create or modify:**
- `Models/Stage.swift`

**Dependencies:** P1-DM-01

**Estimated hours:** 2

---

##### P1-DM-03 · `Project` @Model — Fields & Relationships

**Description:** Create the `Project` SwiftData model. Fields: `id: UUID`, `name: String`, `totalModelCount: Int`, `notes: String?`, `linkGroupId: UUID?`, `createdAt: Date`. Relationships: `collection: Collection?` (optional, inverse), `modelRecords: [ModelRecord]` (inverse, cascade delete). Add computed properties: `modelsInStage(_ stage: Stage) -> [ModelRecord]`, `modelsInStageCount(_ stage: Stage) -> Int`, `isComplete -> Bool` (all records in the last stage). Validate that `totalModelCount >= 1` before insert.

**Key files/types to create or modify:**
- `Models/Project.swift`

**Dependencies:** P1-DM-01, P1-DM-02

**Estimated hours:** 2

---

##### P1-DM-04 · `ModelRecord` @Model — Fields & Relationship to Project

**Description:** Create the `ModelRecord` SwiftData model representing a single physical miniature within a project. Fields: `id: UUID`, `sortIndex: Int`, `createdAt: Date`. Relationship: `project: Project` (inverse, non-optional). Relationship: `currentStage: Stage?` (optional — a model with `nil` stage is "unplaced"; in practice all records start at Stage 0 on project creation). Add a helper `move(to stage: Stage)` that simply sets `currentStage`.

**Key files/types to create or modify:**
- `Models/ModelRecord.swift`

**Dependencies:** P1-DM-02, P1-DM-03

**Estimated hours:** 1

---

##### P1-DM-05 · `Collection` @Model — Fields & Project Relationship

**Description:** Create the `Collection` SwiftData model. Fields: `id: UUID`, `name: String`, `createdAt: Date`. Relationship: `projects: [Project]` (inverse, no cascade — deleting a collection unlinks projects, not deletes them). Add a computed property `projectCount: Int`. Enforce non-empty name at the model layer with a `validate()` helper that throws a descriptive error.

**Key files/types to create or modify:**
- `Models/Collection.swift`

**Dependencies:** P1-DM-03

**Estimated hours:** 1

---

##### P1-DM-06 · Pipeline Singleton Bootstrap & Default Stage Seeding

**Description:** Implement the app startup logic that runs once on first launch (or whenever no `Pipeline` exists). Inside `WarmasterStudioApp` (or a dedicated `AppBootstrap` actor), fetch or create the singleton `Pipeline`. If newly created, insert the six default stages from `Stage.defaultStages()` with correct `sortIndex` values. Wrap in a `@MainActor` async task. Verify idempotency: running bootstrap twice must not create duplicate Pipelines or Stages.

**Key files/types to create or modify:**
- `AppBootstrap.swift`
- `WarmasterStudioApp.swift` (`.task {}` on the root scene)

**Dependencies:** P1-AS-02, P1-DM-01, P1-DM-02

**Estimated hours:** 2

---

#### Feature: Pipeline Config

---

##### P1-PC-01 · Pipeline Config View — Stage List Display

**Description:** Build `PipelineConfigView` — the view shown inside the Settings window's Pipeline tab. It displays a `List` of all stages fetched with `@Query(sort: \Stage.sortIndex)`. Each row shows the stage name and its `sortIndex`. The list is read-only in this task; editing comes in subsequent tasks. Wire this view into the Settings tab created in P1-AS-04.

**Key files/types to create or modify:**
- `Views/Settings/PipelineConfigView.swift`
- `SettingsView.swift` (tab wiring)

**Dependencies:** P1-AS-04, P1-DM-02, P1-DM-06

**Estimated hours:** 2

---

##### P1-PC-02 · Add & Rename Stage

**Description:** Add an "Add Stage" button (toolbar or footer of the list in P1-PC-01) that inserts a new `Stage` with a default name `"New Stage"` at the end (`sortIndex = max + 1`). Implement inline rename: tapping a stage row enters an edit field. On commit, validate non-empty and save. Pressing Escape reverts to the original name. A duplicate-name check should warn (but not block) the user via an inline alert.

**Key files/types to create or modify:**
- `Views/Settings/PipelineConfigView.swift`
- `Views/Settings/StageRowView.swift`

**Dependencies:** P1-PC-01

**Estimated hours:** 2

---

##### P1-PC-03 · Reorder Stages via Drag

**Description:** Enable `.onMove` on the stage list to allow the user to drag stages into a new order. After a move, recalculate and persist `sortIndex` for all stages in sequence (0, 1, 2, …) to maintain a clean ordering invariant. The Kanban board must reactively reflect the new column order when the user returns to it. Test by reordering and verifying `@Query(sort: \Stage.sortIndex)` returns the updated order.

**Key files/types to create or modify:**
- `Views/Settings/PipelineConfigView.swift`

**Dependencies:** P1-PC-02

**Estimated hours:** 2

---

##### P1-PC-04 · Delete Stage with Guard (Blocked if Models Present)

**Description:** Add swipe-to-delete and a Delete button (toolbar context menu) on stage rows. Before deleting, check if any `ModelRecord` currently has `currentStage == thisStage`. If yes, show an alert: *"This stage has X models assigned. Reassign or move them before deleting."* If no models are present, delete the stage from the context and compact the remaining `sortIndex` values. Do not delete the last remaining stage.

**Key files/types to create or modify:**
- `Views/Settings/PipelineConfigView.swift`
- `Views/Settings/StageRowView.swift`

**Dependencies:** P1-PC-03, P1-DM-04

**Estimated hours:** 2

---

#### Feature: Collections

---

##### P1-COL-01 · Collection List Sidebar Section

**Description:** Add a "Collections" section to `SidebarView` that lists all `Collection` objects fetched with `@Query(sort: \Collection.name)`. Tapping a collection navigates the detail area to a filtered project list (or a placeholder if P1-PRJ-03 is not yet done). An "All Projects" entry above the list clears the collection filter. Selection state is propagated as an optional `Collection?` binding.

**Key files/types to create or modify:**
- `Views/Sidebar/SidebarView.swift`
- `Views/Sidebar/CollectionSidebarRow.swift`

**Dependencies:** P1-AS-03, P1-DM-05

**Estimated hours:** 1

---

##### P1-COL-02 · Create & Rename Collection

**Description:** Add a "New Collection" toolbar button (⌘⇧N or a `+` button in the sidebar) that creates a `Collection` with a default name and immediately enters rename mode. Support inline rename via a sidebar row text field (same pattern as P1-PC-02). Validate non-empty and unique names, showing an inline error on conflict. The new collection should appear at its sorted position immediately on save.

**Key files/types to create or modify:**
- `Views/Sidebar/SidebarView.swift`
- `Views/Sidebar/CollectionSidebarRow.swift`

**Dependencies:** P1-COL-01

**Estimated hours:** 2

---

##### P1-COL-03 · Delete Collection (Unlink Projects Gracefully)

**Description:** Add a right-click context menu and swipe-to-delete for collections. Before deleting, show a confirmation alert: *"Deleting '{name}' will unlink its X projects but will not delete them."* On confirmation, set `project.collection = nil` for all projects in the collection, then delete the collection. Verify that unlinked projects still appear under "All Projects" and are not lost.

**Key files/types to create or modify:**
- `Views/Sidebar/CollectionSidebarRow.swift`

**Dependencies:** P1-COL-02

**Estimated hours:** 2

---

#### Feature: Projects

---

##### P1-PRJ-01 · Project Creation Form

**Description:** Build `NewProjectSheet` — a `Sheet` presented modally over the Kanban or project list. Fields: Name (required, `TextField`), Model Count (required, `Stepper` min 1 max 200), Collection (optional, `Picker` from existing collections), Notes (optional, multiline `TextEditor`), Link Group (optional — checkbox "Link to group" that reveals a `UUID` picker or "new group" button). Validate before save. On submit, insert the `Project` model and dismiss. Cancel discards all changes.

**Key files/types to create or modify:**
- `Views/Projects/NewProjectSheet.swift`

**Dependencies:** P1-DM-03, P1-DM-05

**Estimated hours:** 3

---

##### P1-PRJ-02 · ModelRecord Auto-Generation on Project Creation

**Description:** Immediately after a `Project` is saved (in the same transaction), generate exactly `project.totalModelCount` `ModelRecord` instances. Assign each a sequential `sortIndex` (0-based). Set `currentStage` to the first stage (lowest `sortIndex`) in the pipeline. This logic should live in a `ProjectRepository` or extension on the `ModelContext`, not inside a view. Write a unit test to verify correct count and stage assignment.

**Key files/types to create or modify:**
- `Repository/ProjectRepository.swift`
- `Views/Projects/NewProjectSheet.swift` (call repository)

**Dependencies:** P1-PRJ-01, P1-DM-04, P1-DM-06

**Estimated hours:** 2

---

##### P1-PRJ-03 · Project Detail View

**Description:** Build `ProjectDetailView` showing project metadata (name, collection, notes, link group), a summary row (X models, Y complete), and a scrollable list of `ModelRecord` rows with each model's current stage name. The view is navigated to from the Kanban card (⌘-click or a detail button) and from the sidebar collection project list. Support read-only display in this task; editing is handled in P1-PRJ-04.

**Key files/types to create or modify:**
- `Views/Projects/ProjectDetailView.swift`
- `Views/Projects/ModelRecordRowView.swift`

**Dependencies:** P1-PRJ-02

**Estimated hours:** 2

---

##### P1-PRJ-04 · Project Edit & Delete

**Description:** Add an "Edit" toolbar button on `ProjectDetailView` that presents an `EditProjectSheet` pre-populated with current values. Editable fields: Name, Notes, Collection, and `linkGroupId`. The `totalModelCount` is **not** editable after creation (changing model count would require adding/removing `ModelRecord` objects — document this as a known limitation for v1). Add a "Delete Project" destructive button with a confirmation alert. On delete, cascade removes `ModelRecord` objects automatically via SwiftData.

**Key files/types to create or modify:**
- `Views/Projects/EditProjectSheet.swift`
- `Views/Projects/ProjectDetailView.swift`

**Dependencies:** P1-PRJ-03

**Estimated hours:** 2

---

#### Feature: Kanban

---

##### P1-KB-01 · Kanban Board Layout (Horizontal Scroll, Per-Stage Columns)

**Description:** Build `KanbanBoardView` as the home destination. It renders a `ScrollView(.horizontal)` containing an `HStack` of column views, one per stage, ordered by `Stage.sortIndex`. Fetch stages with `@Query(sort: \Stage.sortIndex)`. Each column has a fixed width (~260pt) and fills the vertical space. The board should scroll smoothly with trackpad momentum. Make this the default selected destination in the sidebar.

**Key files/types to create or modify:**
- `Views/Kanban/KanbanBoardView.swift`

**Dependencies:** P1-AS-03, P1-DM-06

**Estimated hours:** 3

---

##### P1-KB-02 · Kanban Column View (Header + Card List)

**Description:** Build `KanbanColumnView` for a single stage. It displays: a column header with the stage name and a count badge (number of projects with ≥1 model in this stage). Below the header is a `ScrollView(.vertical)` containing a `LazyVStack` of card views. The column header is sticky (does not scroll with cards). Apply a subtle background tint to distinguish columns. Pass the `Stage` binding to child card views.

**Key files/types to create or modify:**
- `Views/Kanban/KanbanColumnView.swift`

**Dependencies:** P1-KB-01

**Estimated hours:** 2

---

##### P1-KB-03 · Project-Stage Card View

**Description:** Build `KanbanCardView` for a project as it appears in one specific stage's column. The card shows: project name, collection name (if any), model count in this stage (e.g. "3 / 12 models"), and a mini progress bar across all stages. Cards have a rounded-rect shape with a light drop shadow. Tapping the card navigates to `ProjectDetailView`. If a `linkGroupId` is present, a small chain-link icon appears on the card (full group treatment comes in P1-KB-07).

**Key files/types to create or modify:**
- `Views/Kanban/KanbanCardView.swift`

**Dependencies:** P1-KB-02, P1-PRJ-03

**Estimated hours:** 2

---

##### P1-KB-04 · Card Lifecycle — Appear / Disappear as Models Enter / Leave a Stage

**Description:** A project's card must appear in a stage's column only when `modelsInStageCount > 0`, and disappear when it drops to 0. Implement this filtering in the column's card data source (computed from `@Query` results). Animate card insertion and removal using `.animation(.default)` on the `LazyVStack`. Verify that moving all models out of a stage removes the card, and moving the first model in adds it, both with smooth animation.

**Key files/types to create or modify:**
- `Views/Kanban/KanbanColumnView.swift`

**Dependencies:** P1-KB-03

**Estimated hours:** 2

---

##### P1-KB-05 · +/− Model Buttons on Card (Move One Model at a Time)

**Description:** Add `+` and `−` icon buttons to each `KanbanCardView`. Pressing `+` advances one `ModelRecord` (with the lowest `sortIndex` still in this stage) to the next stage. Pressing `−` regresses one `ModelRecord` (with the highest `sortIndex` in this stage) to the previous stage. Both buttons are disabled when at the first or last stage respectively, or when no models remain to move. Wrap mutations in `modelContext.save()`. Provide haptic feedback via `NSHapticFeedbackManager`.

**Key files/types to create or modify:**
- `Views/Kanban/KanbanCardView.swift`
- `Repository/ModelRecordRepository.swift`

**Dependencies:** P1-KB-04, P1-DM-04

**Estimated hours:** 2

---

##### P1-KB-06 · Drag-and-Drop Card (Move All Models to Target Stage)

**Description:** Implement drag-and-drop for `KanbanCardView`. Dragging a card and dropping it onto a different column moves **all** `ModelRecord` objects currently in the source stage to the target stage in a single `modelContext` transaction. Use SwiftUI's `.draggable` / `.dropDestination` APIs (macOS 14+). Provide a preview image of the card during drag. Dropping onto the same column is a no-op. Animate the source card's disappearance and the target column's card appearance.

**Key files/types to create or modify:**
- `Views/Kanban/KanbanCardView.swift`
- `Views/Kanban/KanbanColumnView.swift`
- `Repository/ModelRecordRepository.swift`

**Dependencies:** P1-KB-05

**Estimated hours:** 3

---

##### P1-KB-07 · Linked Project Grouping (Shared `linkGroupId` Visual Treatment)

**Description:** Projects sharing the same non-nil `linkGroupId` should receive a shared visual treatment on the Kanban board: a matching accent colour stripe on the card left edge, and an optional "group label" popover listing all projects in the group. Assign colours to groups deterministically from `linkGroupId` (e.g. hashing the UUID to a palette of 8 colours). Clicking the chain-link icon on any card shows a `Popover` listing all projects in the same group with their stage distribution.

**Key files/types to create or modify:**
- `Views/Kanban/KanbanCardView.swift`
- `Views/Kanban/LinkGroupPopoverView.swift`
- `Utilities/LinkGroupColour.swift`

**Dependencies:** P1-KB-03

**Estimated hours:** 2

---

#### Feature: Progress Dashboard

---

##### P1-DASH-01 · Dashboard View Layout & Navigation Entry Point

**Description:** Build `DashboardView` as a `ScrollView` destination reachable from the sidebar. At the top, display the global stats header: total projects, total models, and percentage complete. Below, render the per-stage breakdown section (covered in P1-DASH-02) and a collection filter control (P1-DASH-03). Use a clean card-based grid layout. Wire the sidebar "Dashboard" item to navigate here.

**Key files/types to create or modify:**
- `Views/Dashboard/DashboardView.swift`

**Dependencies:** P1-AS-03, P1-DM-03, P1-DM-04

**Estimated hours:** 2

---

##### P1-DASH-02 · Per-Stage Unit Count and Model Count Aggregation

**Description:** For each stage (in `sortIndex` order), compute and display: the number of *projects* with ≥1 model in that stage ("unit count") and the total *model count* across those projects. Display as a table or a set of stat cards. The aggregation must react to SwiftData changes (use `@Query` with computed properties, or a `@Observable` view model). Include a simple horizontal bar chart showing relative model distribution across stages.

**Key files/types to create or modify:**
- `Views/Dashboard/StageStatRowView.swift`
- `Views/Dashboard/DashboardView.swift`

**Dependencies:** P1-DASH-01

**Estimated hours:** 2

---

##### P1-DASH-03 · Collection Filter for Dashboard

**Description:** Add a `Picker` or segmented control at the top of `DashboardView` to filter stats by collection. Options: "All" (default) plus one entry per collection. When a collection is selected, all aggregations in P1-DASH-02 re-compute to include only projects belonging to that collection. The filter state is local to the view (`@State`). Selecting a collection in the sidebar should pre-select the same filter in the Dashboard.

**Key files/types to create or modify:**
- `Views/Dashboard/DashboardView.swift`

**Dependencies:** P1-DASH-02, P1-DM-05

**Estimated hours:** 2

---

#### Testing

---

##### P1-TEST-01 · Unit Tests — Pipeline Singleton & Stage Ordering Logic

**Description:** Write XCTest unit tests (not UI tests) using an in-memory `ModelContainer`. Test cases: (1) bootstrap creates exactly one `Pipeline`; (2) running bootstrap twice doesn't create a second `Pipeline`; (3) default stages are seeded with correct names and sequential `sortIndex`; (4) reordering stages correctly compacts `sortIndex`; (5) adding a new stage assigns `max + 1` index. Use `@MainActor` test methods and `ModelContext` directly.

**Key files/types to create or modify:**
- `WarmasterStudioTests/PipelineTests.swift`

**Dependencies:** P1-DM-06, P1-PC-03

**Estimated hours:** 2

---

##### P1-TEST-02 · Unit Tests — Model Count Transitions & Stage Guard Logic

**Description:** Write unit tests for `ModelRecord` movement logic. Test cases: (1) auto-generation creates exactly `totalModelCount` records on project creation; (2) all records start at stage 0; (3) `+` button advances one record to the next stage; (4) `−` button regresses one record to the previous stage; (5) attempting to delete a stage with assigned models returns the guard error; (6) deleting a stage with zero models succeeds; (7) `modelsInStageCount` returns correct values after moves.

**Key files/types to create or modify:**
- `WarmasterStudioTests/ModelRecordTests.swift`
- `WarmasterStudioTests/StageGuardTests.swift`

**Dependencies:** P1-PRJ-02, P1-KB-05, P1-PC-04

**Estimated hours:** 2

---

##### P1-TEST-03 · UI Smoke Tests — Kanban Board

**Description:** Write `XCUITest` smoke tests verifying the Kanban board renders correctly. Tests: (1) app launches and shows the Kanban board by default; (2) after seeding one project, the card appears in the first stage column; (3) tapping `+` on a card moves the count display; (4) all default stage columns are present after bootstrap; (5) navigating to Settings shows the stage list with six default stages. Use `XCUIApplication` launch arguments to seed test data via an in-memory store.

**Key files/types to create or modify:**
- `WarmasterStudioUITests/KanbanUITests.swift`
- `WarmasterStudioUITests/UITestLaunchArguments.swift`

**Dependencies:** P1-KB-06, P1-DM-06

**Estimated hours:** 3

---

#### Polish

---

##### P1-POL-01 · Empty States for Kanban, Dashboard, Collections, and Projects

**Description:** Implement `EmptyStateView` — a reusable component with an SF Symbol icon, a title, a subtitle, and an optional call-to-action button. Apply it in: (1) `KanbanBoardView` when no projects exist ("No projects yet — add one to get started"); (2) `DashboardView` when no data; (3) the collection project list when a collection has no projects; (4) `PipelineConfigView` if somehow all stages are deleted. The empty state should animate in with a fade.

**Key files/types to create or modify:**
- `Views/Shared/EmptyStateView.swift`
- Applied in `KanbanBoardView`, `DashboardView`, `CollectionDetailView`, `PipelineConfigView`

**Dependencies:** P1-KB-01, P1-DASH-01, P1-COL-01, P1-PC-01

**Estimated hours:** 2

---

##### P1-POL-02 · Accessibility Labels and VoiceOver Support (Phase 1 Views)

**Description:** Audit all Phase 1 views for VoiceOver accessibility. Add `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityValue` to: Kanban cards (project name + model count), `+`/`−` buttons (describe action and count), stage column headers, dashboard stat cells, sidebar items, and all interactive controls. Test with VoiceOver enabled. Ensure tab order is logical and focus moves correctly after drag-and-drop. Fix any contrast issues flagged by the Accessibility Inspector.

**Key files/types to create or modify:**
- `Views/Kanban/KanbanCardView.swift`
- `Views/Kanban/KanbanColumnView.swift`
- `Views/Dashboard/StageStatRowView.swift`
- `Views/Sidebar/SidebarView.swift`

**Dependencies:** P1-KB-06, P1-DASH-02

**Estimated hours:** 3

---

### Phase 2 — Box Art, Recipes, Paint Library & Image Library

---

#### Feature: Box Art Images

---

##### P2-IMG-01 · Image Path Fields on `Project`

**Description:** Extend the `Project` @Model with two new optional fields: `imageBookmarkData: Data?` (Security-scoped bookmark for the external source file) and `imageSandboxPath: String?` (relative path of the locally copied image within the app's sandbox). Define a computed property `resolvedImageURL: URL?` that resolves `imageSandboxPath` relative to the app's Application Support directory. Add a lightweight `ModelMigrationPlan` to handle the schema change without data loss (add optional fields — no migration logic needed, but the version must be bumped).

**Key files/types to create or modify:**
- `Models/Project.swift`
- `AppSchema.swift` (version bump)

**Dependencies:** P1-DM-03

**Estimated hours:** 2

---

##### P2-IMG-02 · Image Import UI — File Picker, Bookmark & Sandbox Copy

**Description:** Add an "Attach Box Art" button to `ProjectDetailView`. Tapping it opens a `NSOpenPanel` filtered to image types (PNG, JPEG, TIFF, HEIC). On selection, create a Security-scoped bookmark (`URL.bookmarkData(options: .withSecurityScope)`), copy the file into `Application Support/WarmasterStudio/BoxArt/{projectID}/image.{ext}`, and save the relative path in `imageSandboxPath`. Handle errors (permission denied, disk full) with user-facing alerts. Verify the file survives app relaunch by loading from `imageSandboxPath`.

**Key files/types to create or modify:**
- `Views/Projects/ProjectDetailView.swift`
- `Repository/ImageImportService.swift`

**Dependencies:** P2-IMG-01, P1-PRJ-03

**Estimated hours:** 3

---

##### P2-IMG-03 · Image Display View in Project Detail

**Description:** Below the project metadata in `ProjectDetailView`, display the attached image (if `resolvedImageURL != nil`) in a `ZoomableImageView` — a custom view wrapping a `magnificationGesture`-enabled `Image` or `AsyncImage`. The image should fill the available width with a fixed aspect-ratio container (~16:9 or intrinsic ratio, capped at 600pt tall). An "X" remove button in the corner deletes the sandbox copy and clears `imageSandboxPath`. This view is the host canvas for Phase 2 recipe pins.

**Key files/types to create or modify:**
- `Views/Projects/ZoomableImageView.swift`
- `Views/Projects/ProjectDetailView.swift`

**Dependencies:** P2-IMG-02

**Estimated hours:** 2

---

##### P2-IMG-04 · Relative Path Persistence and Bookmark Resolution on Relaunch

**Description:** Implement `ImageImportService.resolveImage(for project: Project) -> URL?` which: (1) tries `imageSandboxPath` first (always valid inside the sandbox); (2) falls back to re-resolving `imageBookmarkData` if the sandbox copy is missing and the user still has access to the original. On successful resolution, refreshes the sandbox copy. On failure (file moved/deleted externally), surfaces a warning in the UI ("Box art image is missing") without crashing. Write a unit test simulating a missing sandbox file.

**Key files/types to create or modify:**
- `Repository/ImageImportService.swift`
- `Views/Projects/ZoomableImageView.swift`

**Dependencies:** P2-IMG-03

**Estimated hours:** 2

---

#### Feature: Recipe Pins

---

##### P2-PIN-01 · `RecipePin` @Model — Normalised Coordinates & Recipe Reference

**Description:** Create the `RecipePin` SwiftData model. Fields: `id: UUID`, `normalizedX: Double` (0.0–1.0), `normalizedY: Double` (0.0–1.0), `createdAt: Date`. Relationships: `project: Project` (inverse, cascade delete), `recipe: PaintRecipe?` (optional — a pin may exist before being linked to a recipe). Add a validation helper `clampCoordinates()` ensuring both values are clamped to `[0, 1]`. Add a computed property `cgPoint(in size: CGSize) -> CGPoint` for layout use.

**Key files/types to create or modify:**
- `Models/RecipePin.swift`

**Dependencies:** P2-IMG-01, P2-REC-01

**Estimated hours:** 2

---

##### P2-PIN-02 · Pin Placement UI — Click/Tap on Image to Place Pin

**Description:** Extend `ZoomableImageView` with pin placement mode. A toolbar toggle "Add Pin" enters placement mode (cursor changes to crosshair). Clicking anywhere on the image creates a `RecipePin` at the normalised coordinates of the click. The pin is immediately visible as a circle overlay on the image. When not in placement mode, pins are visible but not interactive for placement (interaction is handled in P2-PIN-03). Support placing multiple pins. Coordinates must account for any zoom/pan transform applied by the zoomable view.

**Key files/types to create or modify:**
- `Views/Projects/ZoomableImageView.swift`
- `Views/Projects/PinOverlayView.swift`

**Dependencies:** P2-PIN-01, P2-IMG-03

**Estimated hours:** 3

---

##### P2-PIN-03 · Pin Popover — Display Linked Recipe Name and First Step

**Description:** Tapping an existing pin in the normal (non-placement) mode opens a `Popover` anchored to the pin circle. The popover shows: the linked recipe name (or "No recipe linked" with a "Link Recipe" button), the first step summary (technique + paint name), and a "View Recipe" button navigating to the full recipe detail. The "Link Recipe" button presents a sheet listing all `PaintRecipe` objects for the project with a search field. Selecting a recipe sets `pin.recipe`.

**Key files/types to create or modify:**
- `Views/Projects/PinPopoverView.swift`
- `Views/Projects/PinOverlayView.swift`

**Dependencies:** P2-PIN-02, P2-REC-03

**Estimated hours:** 2

---

##### P2-PIN-04 · Pin Drag to Reposition on Image

**Description:** Implement drag gesture on each pin overlay circle to allow repositioning. While dragging, the pin moves with the gesture and the overlay updates in real time. On gesture end, compute the new normalised coordinates, clamp them, and save. Dragging near the edge snaps the pin to a minimum inset (e.g. 4px from any edge) so pins are never clipped. Provide a subtle spring animation on release.

**Key files/types to create or modify:**
- `Views/Projects/PinOverlayView.swift`

**Dependencies:** P2-PIN-02

**Estimated hours:** 2

---

##### P2-PIN-05 · Pin Delete

**Description:** Add a "Delete Pin" button inside the pin popover (P2-PIN-03) with a confirmation step (e.g. a secondary "Confirm Delete" button revealed on first tap). On confirmation, delete the `RecipePin` from the model context and animate the overlay circle's removal. Also support right-click context menu → "Delete Pin" on the pin circle directly, bypassing the popover.

**Key files/types to create or modify:**
- `Views/Projects/PinPopoverView.swift`
- `Views/Projects/PinOverlayView.swift`

**Dependencies:** P2-PIN-03

**Estimated hours:** 1

---

#### Feature: Paint Recipes

---

##### P2-REC-01 · `PaintRecipe` @Model — Name, Ordered Steps, Project Relationship

**Description:** Create the `PaintRecipe` SwiftData model. Fields: `id: UUID`, `name: String`, `createdAt: Date`, `notes: String?`. Relationships: `project: Project?` (optional — treat as project-scoped for Phase 2), `steps: [RecipeStep]` (ordered, cascade delete). Add a computed property `sortedSteps: [RecipeStep]` ordered by `RecipeStep.sortIndex`. Validate non-empty name.

**Key files/types to create or modify:**
- `Models/PaintRecipe.swift`

**Dependencies:** P1-DM-03

**Estimated hours:** 2

---

##### P2-REC-02 · `RecipeStep` @Model & `Technique` Enum

**Description:** Create the `RecipeStep` SwiftData model. Fields: `id: UUID`, `sortIndex: Int`, `notes: String?`. Relationships: `recipe: PaintRecipe` (inverse), `paint: Paint?` (optional). Define the `Technique` Swift enum (stored as `RawRepresentable<String>`): `basecoat`, `wash`, `drybrush`, `layer`, `highlight`, `edge`, `stipple`, `glaze`, `varnish`, `other`. Add `displayName: String` and `sfSymbol: String` computed properties on `Technique` for UI use.

**Key files/types to create or modify:**
- `Models/RecipeStep.swift`
- `Models/Technique.swift`

**Dependencies:** P2-REC-01, P2-PLT-01

**Estimated hours:** 2

---

##### P2-REC-03 · Recipe Library List View

**Description:** Build `RecipeLibraryView` accessible from the sidebar or project detail. It shows all `PaintRecipe` objects in a `List`, grouped by project (or ungrouped if global). Each row shows: recipe name, step count, and the techniques used as small chip labels. Tapping a recipe navigates to `RecipeDetailView` (built in subsequent tasks). An empty state ("No recipes yet") is shown when the list is empty. Add a "New Recipe" toolbar button.

**Key files/types to create or modify:**
- `Views/Recipes/RecipeLibraryView.swift`
- `Views/Recipes/RecipeRowView.swift`

**Dependencies:** P2-REC-01

**Estimated hours:** 2

---

##### P2-REC-04 · Recipe Creation Form (Name, Add Steps)

**Description:** Build `NewRecipeSheet` presented on "New Recipe". Fields: Name (required `TextField`), Notes (optional `TextEditor`), Project association (optional `Picker`). After creating the recipe skeleton and saving, immediately navigate to the recipe editor for adding steps (P2-REC-05). The creation form is intentionally minimal — steps are added in the detail editor, not this form.

**Key files/types to create or modify:**
- `Views/Recipes/NewRecipeSheet.swift`

**Dependencies:** P2-REC-03

**Estimated hours:** 2

---

##### P2-REC-05 · Step Editor (Paint Picker, Technique Selector, Notes)

**Description:** Build `RecipeDetailView` (the full recipe editor). It shows a list of `RecipeStep` objects in `sortIndex` order. Each row is an inline editor with: a `Picker` for `Technique` (showing `sfSymbol` + `displayName`), a paint search button opening `PaintPickerSheet` (from Phase 2 Paint Library), and a `TextField` for step notes. Tapping "Add Step" appends a new step at the end with default technique `basecoat` and `nil` paint. The paint picker sheet (P2-PLT-05) is integrated here.

**Key files/types to create or modify:**
- `Views/Recipes/RecipeDetailView.swift`
- `Views/Recipes/RecipeStepRowView.swift`

**Dependencies:** P2-REC-04, P2-PLT-05

**Estimated hours:** 3

---

##### P2-REC-06 · Step Reordering Within Recipe

**Description:** Enable `.onMove` on the step list in `RecipeDetailView` to allow drag-reordering of steps. After a move, recalculate `sortIndex` for all steps (sequential 0-based). Also add "Move Up" / "Move Down" accessibility actions on each step row for keyboard and VoiceOver users. Verify that `sortedSteps` reflects the new order immediately after the move without requiring a view refresh.

**Key files/types to create or modify:**
- `Views/Recipes/RecipeDetailView.swift`

**Dependencies:** P2-REC-05

**Estimated hours:** 2

---

##### P2-REC-07 · Recipe Edit & Delete

**Description:** Make recipe Name and Notes fields editable inline within `RecipeDetailView` (edit mode toggled by a toolbar button). Add a "Delete Recipe" destructive action accessible via toolbar and right-click context menu in the library list. Deletion confirmation alert: *"Deleting this recipe will also remove it from X pins."* On delete, set `pin.recipe = nil` for all `RecipePin` objects referencing this recipe before deleting the recipe itself.

**Key files/types to create or modify:**
- `Views/Recipes/RecipeDetailView.swift`
- `Views/Recipes/RecipeLibraryView.swift`

**Dependencies:** P2-REC-06, P2-PIN-01

**Estimated hours:** 1

---

#### Feature: Paint Library

---

##### P2-PLT-01 · `Paint` @Model — Fields

**Description:** Create the `Paint` SwiftData model. Fields: `id: UUID`, `name: String`, `brand: String`, `hexColour: String?` (e.g. `"#A3B2C1"`), `productCode: String?`, `isUserAdded: Bool`, `notes: String?`. Add a computed property `swatchColour: Color` that parses `hexColour` using a `Color(hex:)` extension (returns `.gray` if nil or invalid). Add a computed `displayName: String` returning `"\(brand) – \(name)"`. Index `name` and `brand` for query performance.

**Key files/types to create or modify:**
- `Models/Paint.swift`
- `Utilities/Color+Hex.swift`

**Dependencies:** P1-AS-01

**Estimated hours:** 2

---

##### P2-PLT-02 · JSON Catalogue Seed File and On-Launch Import

**Description:** Create `paints_catalogue.json` (bundled resource) containing the pre-seeded catalogue of paints. Define a `PaintCatalogueEntry` Codable struct matching the JSON schema. Implement `PaintCatalogueImporter` which: (1) checks if catalogue paints have already been seeded (using a `UserDefaults` flag + catalogue version string); (2) if not seeded, decodes the JSON and batch-inserts `Paint` objects with `isUserAdded = false`; (3) is idempotent — re-running never creates duplicates. Run on first launch inside the bootstrap task (alongside P1-DM-06). Aim for at least 50 representative paints (Citadel, Vallejo, etc.) in the JSON.

**Key files/types to create or modify:**
- `Resources/paints_catalogue.json`
- `Repository/PaintCatalogueImporter.swift`
- `AppBootstrap.swift`

**Dependencies:** P2-PLT-01, P1-DM-06

**Estimated hours:** 3

---

##### P2-PLT-03 · My Paints CRUD (Add, Edit, Delete User-Defined Paints)

**Description:** Build `MyPaintsView` (a tab or section within the paint library) showing only `isUserAdded == true` paints. Include a "New Paint" button opening `NewPaintSheet` with fields: Name, Brand, Hex Colour (text field with a live swatch preview), Product Code, Notes. Inline validation: hex must match `#RRGGBB` or `#RGB` pattern. Edit via swipe-to-reveal Edit button or double-click on row. Delete with swipe or context menu — no confirmation needed for user paints. Catalogue paints (`isUserAdded == false`) have no edit or delete controls.

**Key files/types to create or modify:**
- `Views/PaintLibrary/MyPaintsView.swift`
- `Views/PaintLibrary/NewPaintSheet.swift`
- `Views/PaintLibrary/PaintRowView.swift`

**Dependencies:** P2-PLT-01

**Estimated hours:** 2

---

##### P2-PLT-04 · Colour Swatch Rendering from Hex String

**Description:** Implement `Color+Hex.swift` with `init?(hex: String)` that handles `#RRGGBB`, `#RGB`, and optionally `#RRGGBBAA` strings. Build a reusable `ColourSwatchView(hex:)` showing a filled rounded rect of the colour with a thin border. Use it in: paint library rows, paint picker in step editor, and the "My Paints" creation form preview. Handle invalid or nil hex gracefully (grey placeholder swatch with a diagonal line). Write a unit test for the hex parser covering edge cases (short form, missing `#`, invalid chars, empty string).

**Key files/types to create or modify:**
- `Utilities/Color+Hex.swift`
- `Views/Shared/ColourSwatchView.swift`

**Dependencies:** P2-PLT-01

**Estimated hours:** 1

---

##### P2-PLT-05 · Unified Paint Search View (Catalogue + My Paints, Filterable by Brand)

**Description:** Build `PaintPickerSheet` — a searchable sheet used when picking a paint for a recipe step. It shows a unified list of all paints (catalogue + My Paints) with real-time search filtering on name, brand, and product code. A `Picker` control at the top filters by brand (`"All"` + one entry per distinct brand). My Paints appear in a separate section or with a distinct badge. Tapping a paint row dismisses the sheet and returns the selected `Paint` to the caller. Also build a standalone `PaintLibraryView` for browsing all paints from the sidebar.

**Key files/types to create or modify:**
- `Views/PaintLibrary/PaintPickerSheet.swift`
- `Views/PaintLibrary/PaintLibraryView.swift`

**Dependencies:** P2-PLT-03, P2-PLT-04

**Estimated hours:** 3

---

#### Testing

---

##### P2-TEST-01 · Unit Tests — Recipe Step Ordering and Technique Enum Coverage

**Description:** Write unit tests for recipe logic. Test cases: (1) a new recipe has zero steps; (2) adding a step appends at the correct `sortIndex`; (3) moving a step recalculates all indexes correctly; (4) all `Technique` cases have non-empty `displayName` and `sfSymbol`; (5) deleting a recipe sets `pin.recipe = nil` on all linked pins; (6) `sortedSteps` returns steps in ascending `sortIndex` order even if inserted out of order.

**Key files/types to create or modify:**
- `WarmasterStudioTests/RecipeTests.swift`

**Dependencies:** P2-REC-07

**Estimated hours:** 2

---

##### P2-TEST-02 · Unit Tests — Paint Catalogue Seeding (No Duplicates, Correct Count)

**Description:** Write unit tests for `PaintCatalogueImporter`. Test cases: (1) running the importer on an empty store inserts the expected number of paints; (2) running the importer twice on the same store does not create duplicates; (3) all seeded paints have `isUserAdded == false`; (4) `Color(hex:)` correctly parses all hex codes in the JSON (no paints render grey from invalid hex); (5) user-added paints (`isUserAdded == true`) are not modified by the importer.

**Key files/types to create or modify:**
- `WarmasterStudioTests/PaintCatalogueTests.swift`

**Dependencies:** P2-PLT-02, P2-PLT-04

**Estimated hours:** 2

---

##### P2-TEST-03 · Unit Tests — Pin Coordinate Clamping and Normalisation

**Description:** Write unit tests for `RecipePin` coordinate logic. Test cases: (1) `clampCoordinates()` clamps values below 0 to 0 and above 1 to 1; (2) `cgPoint(in:)` returns the correct `CGPoint` for boundary values (0,0), (1,1), and (0.5, 0.5); (3) a pin created via the UI placement gesture has coordinates within `[0,1]`; (4) deleting a pin removes it from the project's pin collection; (5) a pin with `nil` recipe is valid and can be saved.

**Key files/types to create or modify:**
- `WarmasterStudioTests/RecipePinTests.swift`

**Dependencies:** P2-PIN-05

**Estimated hours:** 2

---

##### P2-TEST-04 · UI Tests — Image Attach, Place Pin, Link Recipe End-to-End

**Description:** Write an `XCUITest` end-to-end test for the Phase 2 image + pin + recipe flow. Steps: (1) create a project via the UI; (2) attach a test image (copy a known test PNG to a temp location first); (3) verify the image renders in the project detail; (4) enter pin placement mode and click to place a pin; (5) open the pin popover and link a pre-seeded recipe; (6) verify the popover shows the recipe name and first step summary. Use launch arguments to pre-seed one recipe and one paint.

**Key files/types to create or modify:**
- `WarmasterStudioUITests/ImagePinRecipeUITests.swift`

**Dependencies:** P2-PIN-03, P2-IMG-03, P2-REC-05

**Estimated hours:** 3

---

#### Polish

---

##### P2-POL-01 · Empty States for Recipe Library and Paint Library

**Description:** Apply `EmptyStateView` (from P1-POL-01) to Phase 2 screens: (1) `RecipeLibraryView` when no recipes exist — "No recipes yet. Add one from a project's detail view."; (2) `PaintLibraryView` when the catalogue fails to seed — "Paint library is unavailable."; (3) `MyPaintsView` when no user paints exist — "Add your own paints to personalise your recipes.". Also add a loading state for the catalogue seed (show `ProgressView` if the importer is running).

**Key files/types to create or modify:**
- `Views/Recipes/RecipeLibraryView.swift`
- `Views/PaintLibrary/PaintLibraryView.swift`
- `Views/PaintLibrary/MyPaintsView.swift`
- `Views/Shared/EmptyStateView.swift`

**Dependencies:** P2-REC-03, P2-PLT-05, P1-POL-01

**Estimated hours:** 1

---

##### P2-POL-02 · Accessibility Labels for Image Canvas, Pins, and Swatches

**Description:** Audit all Phase 2 views for VoiceOver and keyboard accessibility. Add `.accessibilityLabel` to: each pin circle (label includes linked recipe name or "Unlinked pin"); colour swatches (label reads the hex value or "No colour"); technique picker cells; recipe step rows (summarises technique and paint name). Ensure the image canvas announces "Box art image. Double-tap to manage pins." in VoiceOver. Verify `PaintPickerSheet` can be navigated entirely by keyboard. Run Accessibility Inspector and resolve any contrast warnings.

**Key files/types to create or modify:**
- `Views/Projects/PinOverlayView.swift`
- `Views/Shared/ColourSwatchView.swift`
- `Views/Recipes/RecipeStepRowView.swift`
- `Views/PaintLibrary/PaintPickerSheet.swift`

**Dependencies:** P2-PIN-03, P2-PLT-05

**Estimated hours:** 2

---

#### Feature: Image Library

---

##### P2-LIB-01 · `ImageLibraryService` — Folder Scanner

**Description:** Implement `ImageLibraryService` as a non-SwiftData service that scans `~/Library/Application Support/com.warmasterstudio.app/ImageLibrary/` at runtime. Walk two levels deep: `{System}/{Faction}/{file}`. Emit an array of `LibraryImage` structs (id: UUID, name: String derived from filename, system: String, faction: String, url: URL). Expose a `scanLibrary() -> [LibraryImage]` method called on view appear. No database; the filesystem is the index. Support image extensions: jpg, jpeg, png, webp, heic.

**Key files/types to create or modify:**
- `Services/ImageLibraryService.swift`
- `Models/LibraryImage.swift` (value type)

**Dependencies:** P2-IMG-01

**Estimated hours:** 2

---

##### P2-LIB-02 · Image Library Sidebar Entry and Game System Selector

**Description:** Add an "Image Library" entry to the sidebar (`SidebarItem` enum). The `ImageLibraryView` root shows a top-level picker or segmented control for game systems derived from the scanned library. Selecting a system filters the displayed content. Systems are sorted alphabetically. If the ImageLibrary folder does not exist or is empty, show a clear empty state: "No images found. Add images to ~/Library/Application Support/com.warmasterstudio.app/ImageLibrary/."

**Key files/types to create or modify:**
- `Views/Library/ImageLibraryView.swift`
- `Views/AppShell/ContentView.swift` (sidebar entry)

**Dependencies:** P2-LIB-01, P1-AS-03

**Estimated hours:** 1

---

##### P2-LIB-03 · Faction Chip Filter Strip with `WrapLayout`

**Description:** Build the faction filter strip at the top of `ImageLibraryView`. Display faction chips using a custom `WrapLayout: Layout` conformance so chips reflow into multiple rows on narrow windows — do not use `ScrollView` + `HStack` (which clips chips) or `GeometryReader` (which breaks intrinsic height). An "All" chip is always first. Selecting a chip filters the grid; selecting "All" clears the filter. The strip has a fixed background colour and sits above the image grid without overlapping it.

**Key files/types to create or modify:**
- `Views/Library/ImageLibraryView.swift` (WrapLayout + factionStrip)

**Dependencies:** P2-LIB-02

**Estimated hours:** 2

---

##### P2-LIB-04 · Image Grid with `LazyVGrid` Thumbnails

**Description:** Implement the image grid inside `ImageLibraryView` using `LazyVGrid` with adaptive columns (minimum 160pt). Each cell shows the image thumbnail (loaded on demand with `NSImage`) and the filename label below. Cells respond to hover (dim overlay) to reveal action buttons. The grid is filtered by the active faction chip. Images are sorted by filename within each faction.

**Key files/types to create or modify:**
- `Views/Library/ImageLibraryView.swift` (grid + `LibraryManageCell`)

**Dependencies:** P2-LIB-03

**Estimated hours:** 2

---

##### P2-LIB-05 · Lightbox Overlay Viewer with Prev/Next Navigation

**Description:** Tapping any grid cell opens a full-size lightbox. Implement as an `.overlay` on `ImageLibraryView` body (not `.sheet`) so the dimmed backdrop is tappable to dismiss — macOS sheets are modal windows that cannot be clicked outside. The overlay contains: a semi-transparent black backdrop (tappable to dismiss), the image fitted to a max of 960×720, and prev/next buttons to navigate within the current filtered image list. The overlay uses `.transition(.opacity)` with a 0.2s animation.

**Key files/types to create or modify:**
- `Views/Library/ImageLibraryView.swift` (overlay + `ImageLightboxView`)

**Dependencies:** P2-LIB-04

**Estimated hours:** 2

---

##### P2-LIB-06 · Move to Faction — Context Menu, File Move, Grid Refresh

**Description:** Add a right-click context menu to each image cell with a "Move to Faction" submenu. The submenu lists all factions in the same game system (excluding the current faction). Selecting a faction moves the file on disk using `FileManager.moveItem(at:to:)`, creating the target faction folder if needed. After a successful move, rescan the library and refresh the grid. Show an alert on move failure (e.g. name collision).

**Key files/types to create or modify:**
- `Views/Library/ImageLibraryView.swift` (context menu)
- `Services/ImageLibraryService.swift` (moveImage helper)

**Dependencies:** P2-LIB-04

**Estimated hours:** 2

---

##### P2-LIB-07 · Create Project from Image Sheet

**Description:** Each image cell has a "+" hover button (top-left, revealed on hover). Tapping it opens `CreateProjectFromImageSheet` pre-filled with: name from filename (extension stripped), collection from faction name (auto-create if absent), model count = 1 (editable via `TextField + Stepper`), box art = the selected image (imported via `ImageService`). On submit, create the project, import box art, dismiss the sheet. Validate name is non-empty and model count ≥ 1.

**Key files/types to create or modify:**
- `Views/Library/CreateProjectFromImageSheet.swift`
- `Services/ImageService.swift` (image import)

**Dependencies:** P2-LIB-04, P2-IMG-02, P1-PRJ-01

**Estimated hours:** 3

---

## Appendix A — Suggested Sprint Groupings

If working in weekly sprints, here is a suggested grouping:

| Sprint | Tasks | Goal |
|---|---|---|
| 1 | P1-AS-01 to P1-AS-05, P1-DM-01 to P1-DM-06 | Runnable app shell with working data layer |
| 2 | P1-PC-01 to P1-PC-04, P1-COL-01 to P1-COL-03 | Pipeline config & collections fully functional |
| 3 | P1-PRJ-01 to P1-PRJ-04, P1-KB-01 to P1-KB-04 | Projects exist, Kanban renders |
| 4 | P1-KB-05 to P1-KB-07, P1-DASH-01 to P1-DASH-03 | Kanban interactions + Dashboard complete |
| 5 | P1-TEST-01 to P1-TEST-03, P1-POL-01 to P1-POL-02 | Phase 1 tested and polished — ship MVP |
| 6 | P2-IMG-01 to P2-IMG-04, P2-PIN-01 to P2-PIN-05 | Box art and recipe pins |
| 7 | P2-PLT-01 to P2-PLT-05 | Paint library (catalogue + My Paints) |
| 8 | P2-REC-01 to P2-REC-07 | Recipe library end-to-end |
| 9 | P2-TEST-01 to P2-TEST-04, P2-POL-01 to P2-POL-02 | Phase 2 tested and polished — ship v2 |

---

## Appendix B — Key Architectural Decisions

**SwiftData only, no third-party dependencies.** All persistence, querying, and reactive updates use SwiftData `@Query` and `ModelContext`. No Combine publishers, no external ORM.

**Pipeline singleton invariant.** Only one `Pipeline` object ever exists. All code that needs stages must fetch it via `Pipeline.fetch(in: context)`. Views must not create a second Pipeline.

**`sortIndex` as the sole ordering mechanism.** Both `Stage` and `RecipeStep` use an integer `sortIndex`. After any reorder, the full sequence is always compacted back to 0, 1, 2, … to prevent gaps. Never use `createdAt` for display ordering.

**Security-scoped bookmarks for images.** macOS sandboxing requires bookmark data to maintain access to user-selected files across launches. Always store both `imageBookmarkData` and the sandbox-local `imageSandboxPath`. Prefer the sandbox copy at runtime.

**No model count editing after creation.** Changing `totalModelCount` post-creation would require adding or deleting `ModelRecord` objects, with ambiguous semantics (which model is removed? what stage does a new model start in?). This is a deliberate v1 constraint. Future work may introduce a `resizeProject(to:)` operation.

**Normalised pin coordinates.** Recipe pin positions are stored as `(normalizedX, normalizedY)` in `[0, 1]` space so they remain valid regardless of view size or zoom level. Always convert to/from `CGPoint` using `cgPoint(in: containerSize)` at render time, never store screen coordinates.
