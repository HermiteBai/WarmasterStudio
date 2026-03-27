# Warmaster Studio — Product Requirements Document

**Version:** 1.4
**Date:** March 2026
**Platform:** macOS (native SwiftUI)
**Status:** Active development

---

## Table of Contents

1. [Overview](#1-overview)
2. [Entities & Data Model](#2-entities--data-model)
3. [Features](#3-features)
4. [Interaction Design](#4-interaction-design)
5. [Tech Stack](#5-tech-stack)
6. [Roadmap & Phasing](#6-roadmap--phasing)

> **v1.4 changes:** Added §3.8 Image Library (browse, lightbox, move-to-faction, create-project-from-image). Pipeline configuration moved from Settings window to Kanban toolbar (§3.1). Image Library storage documented in §5.4. Navigation updated in §4.1.

---

## 1. Overview

### 1.1 Product Summary

Warmaster Studio is a native macOS application for hobbyists who paint Warhammer miniatures. It provides a structured way to plan and track painting projects from raw sprues through to completion, with support for paint recipe management and per-model progress tracking.

The app is designed around the reality of miniature painting: work is non-linear, units often span multiple stages simultaneously, and painters need both a high-level view of their collection and fine-grained control over individual model progress.

### 1.2 Design Philosophy

- **The Kanban board is the home screen.** The board is the primary working surface, not a supplementary view. It should load instantly and feel fast to interact with.
- **Models are first-class citizens.** Progress is tracked at the individual model level, not just the unit level.
- **Pipeline is global and configurable.** One shared pipeline applies to all projects, reflecting the reality that most painters use the same workflow across their entire hobby.
- **Recipes are reusable assets.** Paint recipes live in a library and are referenced by projects, not duplicated per project.

### 1.3 Target User

A Warhammer hobbyist who:
- Maintains multiple active painting projects (units, warbands, Kill Teams, display pieces)
- Wants to track how many models are at each stage of painting
- Has recurring paint recipes they want to document and reuse
- May have models from many different factions or game systems

---

## 2. Entities & Data Model

### 2.1 Pipeline

The Pipeline is a **global singleton** — there is exactly one pipeline per installation, shared across all projects and collections.

**Properties:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `stages` | `[Stage]` | Ordered array; order determines Kanban column sequence |

**Behaviour:**
- The pipeline is created on first launch with default stages (see §2.2).
- Changes to the pipeline affect all projects immediately.
- A stage cannot be deleted while any models are assigned to it. The app shows an error and blocks deletion until all models have been moved out of that stage.

---

### 2.2 Stage

A Stage is one column in the Kanban board. The pipeline is a flat, ordered list of stages — there are no sub-stages or intermediate checklists.

**Default stages (in order):**

1. On Sprue
2. Assembled
3. Primed
4. Painting
5. Done

**Properties:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | String | User-editable |
| `position` | Int | Determines display order |

**Constraints:**
- Stage names must be non-empty.
- A minimum of one stage must always exist.
- A stage **cannot be deleted** if any `ModelRecord` has `currentStageId` pointing to it. The user must move all models out first.
- Stages can be added, renamed, and reordered freely.

---

### 2.3 Project

A Project represents a single unit type (e.g. "Intercessor Squad", "Necron Warriors", "Mortarion"). It is the primary organisational unit in the app.

**Properties:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | String | e.g. "Intercessor Squad" |
| `modelCount` | Int | Set at creation; fixed; minimum 1 |
| `collectionId` | UUID? | Optional foreign key to Collection |
| `linkGroupId` | UUID? | Optional; projects sharing the same value are visually grouped on the Kanban (see §3.3) |
| `notes` | String? | Freeform text; supports multi-line |
| `boxArtImagePath` | String? | Relative path to box art image file in app sandbox (Phase 2) |
| `createdAt` | Date | Timestamp |

**Behaviour:**
- Model count is fixed at creation. To add more models of the same unit type, the user creates a new project and optionally links it to the existing one.
- A project has N `ModelRecord` entries created at project-creation time, all starting in the first pipeline stage.
- A project may belong to zero or one Collection.
- A project may belong to zero or one link group (identified by a shared `linkGroupId` UUID).

**Linked projects:**
- Two or more projects can be linked by assigning them the same `linkGroupId`.
- Linking is non-destructive — linked projects remain fully independent entities with their own model counts, collections, and notes.
- Linking is reversible; unlinking a project sets its `linkGroupId` to `nil`.
- A new `linkGroupId` is generated (new UUID) when the user links two previously unlinked projects. Adding further projects to an existing group reuses that group's UUID.

---

### 2.4 ModelRecord

A ModelRecord tracks the state of one individual model within a Project.

**Properties:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `projectId` | UUID | Foreign key to Project |
| `currentStageId` | UUID | Foreign key to Stage |

**Behaviour:**
- All models in a project start in the first pipeline stage when the project is created.
- Models move between stages via Kanban interactions (drag-and-drop, +/− buttons). There are no intermediate checklist gates.
- When a Stage is deleted, deletion is blocked at the data layer if any ModelRecord references it.

---

### 2.5 Collection

A Collection is a flexible grouping of projects. It is intentionally generic to cover armies, warbands, Kill Teams, display collections, narrative campaigns, and any other grouping the user finds useful.

**Properties:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | String | e.g. "Space Marines 1st Company", "Underworlds Season 4" |
| `notes` | String? | Optional freeform description |
| `createdAt` | Date | Timestamp |

**Behaviour:**
- A project belongs to at most one Collection.
- Collections are user-created and user-managed.
- Collections are used as a filter dimension in the progress dashboard.
- Deleting a collection does not delete its projects; it unlinks them (`collectionId` set to `nil`).

---

### 2.6 PaintRecipe (Phase 2)

A PaintRecipe is a reusable, ordered sequence of paint steps associated with a named surface area on a miniature.

**Properties:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | String | e.g. "Power Armour — Blue", "Basing — Ash Wastes" |
| `steps` | `[RecipeStep]` | Ordered list |
| `notes` | String? | Optional |
| `createdAt` | Date | Timestamp |

**RecipeStep:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `position` | Int | Display order |
| `paintId` | UUID? | Optional reference to a Paint entry (catalogue or user) |
| `paintName` | String | Stored directly for portability if no library entry is linked |
| `brand` | String? | e.g. "Citadel", "Vallejo", "Scale75" |
| `paintType` | String? | e.g. "Base", "Contrast", "Model Color" |
| `hexColour` | String? | Copied from linked Paint at step-creation time for display without a live join |
| `technique` | Enum | `basecoat`, `wash`, `drybrush`, `highlight`, `layer`, `contrast`, `shade`, `texture`, `varnish`, `other` |
| `notes` | String? | e.g. "Thin to 2:1 ratio" |

---

### 2.7 RecipePin (Phase 2)

A RecipePin links a PaintRecipe to a specific click location on a project's box art image.

**Properties:**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `projectId` | UUID | Foreign key to Project |
| `recipeId` | UUID | Foreign key to PaintRecipe |
| `label` | String | Surface area label, e.g. "Shoulder pad", "Cloak" |
| `xNormalized` | Double | Click X position as fraction of image width (0.0–1.0) |
| `yNormalized` | Double | Click Y position as fraction of image height (0.0–1.0) |

---

### 2.8 Paint (Phase 2)

The paint database is split into two distinct sources that are queried together in the UI but managed separately in the data layer.

**Seeded catalogue entry (read-only):**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | String | e.g. "Macragge Blue", "Prussian Blue" |
| `brand` | String | e.g. "Citadel", "Vallejo", "Army Painter" |
| `paintType` | String | Brand-specific range or type (see below) |
| `hexColour` | String | 6-digit hex colour value (e.g. `#2B4B8C`); required |

Seeded entries are **immutable** at runtime. They carry no edit or delete affordances in the UI.

**User paint entry ("My Paints", read-write):**

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | String | User-supplied |
| `brand` | String | User-supplied |
| `paintType` | String | User-supplied |
| `hexColour` | String | Required; user picks or types a hex value |
| `notes` | String? | Optional freeform notes |

User paint entries are fully editable and deletable at all times.

**`paintType` examples by brand:**

| Brand | Example types |
|---|---|
| Citadel / Games Workshop | Base, Layer, Shade, Contrast, Technical, Dry, Air |
| Vallejo | Model Color, Game Color, Model Air, Panzer Aces, Mecha Color |
| Army Painter | Warpaints, Speedpaint, Quickshade Ink, Primer |
| Scale75 | Scale Color, Fantasy & Games, Instant Colors |
| Reaper | Core Colors, Bones Colors, HD Colors, Learn to Paint |
| AK Interactive | Real Colors, 3rd Gen Acrylics, Xtreme Metal |

**Pre-seeded library:**
- Bundled as a static JSON or Swift resource file compiled into the app.
- Covers all major current ranges for the brands listed above.
- Loaded into a dedicated read-only store (or an in-memory lookup) on first launch; never modified by user actions.

**Implementation note:** The two sources can be modelled as separate SwiftData `@Model` types (e.g. `CataloguePaint` and `UserPaint`) conforming to a shared `PaintEntry` protocol, or as a single model with an `isUserAdded` flag enforced read-only in the service layer. Either approach must ensure seeded entries cannot be mutated or deleted via any code path.

---

## 3. Features

### 3.1 Pipeline Configuration

**Location:** Kanban board toolbar — "Manage Stages" button (list.bullet.indent icon). The Settings window (⌘,) has been removed; pipeline configuration is accessed directly from the board.

Users can configure the global pipeline from the Manage Stages sheet:

- **Add a stage** — appended at the end by default; user can reorder immediately.
- **Rename a stage** — inline edit on the stage name.
- **Reorder stages** — drag-and-drop reordering within the settings list. The Kanban column order reflects this immediately.
- **Delete a stage** — blocked if any models currently occupy that stage. The app shows an explanatory error (e.g. "Move all models out of 'Primed' before deleting it.") and does not proceed. Once the stage is empty, deletion requires a confirmation prompt.

---

### 3.2 Project Management

**Creating a project:**
- User provides: name (required), model count (required, minimum 1), collection (optional, selectable from existing collections or create new inline), notes (optional).
- On creation, N `ModelRecord` entries are created and placed in the first pipeline stage.

**Editing a project:**
- Name, collection, and notes are editable post-creation.
- Model count is fixed at creation. To track additional models of the same unit type, the user creates a new project and links it to the original.

**Linking projects:**
- From the project detail view (or a contextual menu on the Kanban card), the user can link a project to another project.
- Linked projects share a `linkGroupId` and are visually grouped on the Kanban board.
- Projects can be unlinked at any time; this sets their `linkGroupId` to `nil` without affecting any other data.

**Deleting a project:**
- Requires confirmation.
- All associated ModelRecords and RecipePins are deleted.
- If the project was part of a link group and it was the last member, the link group dissolves (no orphan `linkGroupId` references remain).

**Project detail view:**
- Shows project metadata (name, collection, link group, notes, creation date).
- Shows model distribution across stages.
- Phase 2: Box art image with recipe pins.

---

### 3.3 Kanban Home Screen

The Kanban board is the app's home screen — it is the first thing the user sees on launch.

**Layout:**
- Horizontal scroll of columns, one column per pipeline stage.
- Each column has a header showing the stage name and total model count at that stage.
- Cards within a column are vertically stacked.

**Cards:**
- A card represents all models from one project that are currently at one stage.
- If a project's models are distributed across multiple stages, multiple cards exist (one per stage per project).
- Card content:
  - Unit name (project name)
  - Collection name (if assigned)
  - Model count at this stage (e.g. "3 models")
- Cards are visually distinct from column headers.

**Linked project grouping:**
- Cards belonging to projects in the same link group are visually grouped together within each column — e.g. rendered with a shared coloured border, bracket, or background band.
- The grouping is consistent across all columns so the user can visually trace the full spread of a linked set of projects across the board.
- Linked cards within a column are sorted together but otherwise behave identically to unlinked cards (each is independently draggable, has its own +/− buttons, etc.).

---

### 3.4 Model Progress Interactions

Three mechanisms exist for moving models between stages:

#### 3.4.1 Drag and Drop (Card-level)
- Dragging a card from one column and dropping it onto another column moves **all models on that card** to the target stage.
- There are no intermediate checklist gates; the drop always succeeds if the target is a valid stage column.
- Dropping onto the same column the card originated from is a no-op.

#### 3.4.2 Plus Button (+)
- A "+" button on each card moves **one model** from this card's stage to the next stage.
- If the card has only 1 model remaining, pressing "+" causes the card to disappear from the current column and a new/updated card to appear in the next column.
- The "+" button is disabled on cards in the final stage (no next stage exists).

#### 3.4.3 Minus Button (−)
- A "−" button on each card moves **one model** back to the previous stage.
- The "−" button is disabled on cards in the first stage (no previous stage exists).

**Card lifecycle:**
- When a card's model count reaches 0, it disappears from the board.
- When a model arrives at a stage where no card yet exists for that project, a new card appears.

---

### 3.5 Progress Dashboard

**Location:** Dedicated sidebar section or toolbar navigation item.

**Filters:**
- **Scope:** All collections vs. a specific collection (picker/dropdown)
- **Granularity:** Unit count vs. model count (toggle)

**Display:**
- For each pipeline stage: count and percentage of units (or models) currently at that stage.
- Summary: total units, total models, percentage "Done".
- Displayed as a combination of data table and optional bar/progress chart.

---

### 3.6 Paint Recipe Management (Phase 2)

#### 3.6.1 Box Art Image
- From a project's detail view, the user can attach a box art image via drag-and-drop or a file picker.
- The image file is copied into the app's sandboxed local file system (Application Support directory). The original file is not modified.
- `Project.boxArtImagePath` stores a relative path to the copied file within the sandbox. SwiftData does not store the image data directly.
- Images are local-only and are **not** synced via CloudKit (Phase 3 sync applies to metadata only).

#### 3.6.2 Recipe Pins
- The user clicks anywhere on the attached box art image to place a pin.
- A small visual pin marker (numbered circle) is rendered at the click position, overlaid on the image.
- Clicking an existing pin opens a **popover** anchored to that pin showing:
  - The surface area label (e.g. "Left pauldron")
  - An ordered list of paint steps for the linked recipe, each displaying:
    - Colour swatch (filled circle from hex value)
    - Paint name and brand
    - Paint type (e.g. "Base", "Contrast")
    - Technique (e.g. "Basecoat", "Wash")
    - Optional step notes
- From the popover, the user can edit the label, swap the linked recipe, or delete the pin.
- Placing a new pin opens the same popover in "create" mode: the user enters a label and selects or creates a recipe.

#### 3.6.3 Recipe Library
- A dedicated library view shows all saved recipes.
- Recipes can be created, edited, duplicated, and deleted.
- Each recipe is a named, ordered list of `RecipeStep` items.
- When editing a step, the user can type a paint name freehand or search the paint library (catalogue + My Paints).

#### 3.6.4 Paint Library

The Paint Library is a unified, searchable database of miniature paints backed by two sources: a read-only pre-seeded catalogue and a fully editable "My Paints" section.

**Pre-seeded catalogue (read-only):**
- The app ships with a comprehensive built-in database covering Citadel/Games Workshop, Vallejo, Army Painter, Scale75, Reaper, AK Interactive, and other major brands.
- Each entry includes: brand, paint type/range, paint name, and a hex colour value.
- Seeded entries carry **no edit or delete affordances** in the UI — they are display-only reference data.
- The seeded data is compiled into the app bundle (JSON or Swift resource) and loaded on first launch.

**"My Paints" — user catalogue (read-write):**
- Users can add custom paints using the same fields: brand, type, name, hex colour, and optional notes.
- Useful for discontinued paints, new releases not yet in the seeded catalogue, or lesser-known brands.
- All user-added entries are fully editable and deletable at any time.
- Managed via an "Add Paint" button within the My Paints section.

**Visual distinction between sources:**
- In all views (library browser and paint picker), catalogue paints and My Paints are visually distinguished — e.g. via section grouping, a "My Paints" badge or label, or a subtle background tint.
- The distinction must be clear enough that users understand which entries they own and can edit.

**Colour swatches:**
- Every paint entry renders a small filled circle (colour swatch) derived from its hex colour value.
- Swatches appear in: the paint library list, search/autocomplete results when building recipe steps, and within the recipe step list inside a recipe pin popover.
- Implemented via a `Color(hex:)` SwiftUI extension that parses the stored hex string.

**Search and filtering:**
- The library is searchable by paint name, brand, and type — results span both the catalogue and My Paints simultaneously.
- Filterable by brand (multi-select) and paint type.
- My Paints entries may optionally be surfaced first in results or receive a distinct visual treatment to aid discoverability.
- The unified search result set is used as the autocomplete source when building `RecipeStep` entries.

---

### 3.7 Collection Management

- Collections are managed from a dedicated sidebar section.
- Users can: create, rename, and delete collections.
- Deleting a collection does **not** delete its projects; it unlinks them (`collectionId` set to `nil`).

---

### 3.8 Image Library

The Image Library is a built-in browser for Games Workshop product images, stored locally in Application Support. It is accessible from the sidebar and is distinct from project-level box art.

#### 3.8.1 Image Storage

- Images are stored in `~/Library/Application Support/com.warmasterstudio.app/ImageLibrary/`.
- The folder structure is `{Game System}/{Faction}/{filename.jpg}`.
- The library root is never bundled in the app binary — it is populated by the user (or an onboarding download flow) and persists across app reinstalls.
- Reinstalling the app does **not** wipe image data; Application Support is independent of the app bundle.

#### 3.8.2 Browsing

- The sidebar lists all game systems found in the library root.
- Selecting a game system shows a faction filter strip at the top and an image grid below.
- **Faction filter strip:** Horizontal chip group using a wrap layout (multiple rows) so all factions are visible regardless of window width. An "All" chip is always first.
- The image grid shows all images for the selected system (filtered by active faction chip).
- Each image cell shows the image thumbnail and its filename as the label.

#### 3.8.3 Lightbox Viewer

- Clicking any image thumbnail opens a full-size lightbox overlay.
- The lightbox dims the background with a semi-transparent overlay.
- Clicking the dimmed background dismisses the lightbox.
- The lightbox supports previous/next navigation across all images in the current filtered view.

#### 3.8.4 Move to Faction

- Right-clicking an image thumbnail shows a context menu with a **"Move to Faction"** submenu.
- The submenu lists all factions within the same game system.
- Selecting a faction moves the image file to the corresponding folder on disk and refreshes the grid immediately.
- This is the primary mechanism for correcting miscategorised images.

#### 3.8.5 Create Project from Image

- Each image thumbnail has a **"+"** hover button (top-left corner).
- Tapping it opens a **Create Project from Image** sheet pre-filled with:
  - **Name:** derived from the image filename (extension stripped).
  - **Collection:** the image's faction name. If a collection with that name already exists it is pre-selected; if not, a new collection is created on submit.
  - **Box art:** the selected image is automatically imported as the project's box art.
  - **Model count:** editable via a `TextField + Stepper` combo (minimum 1).
- The sheet allows the user to adjust any field before creating.
- On creation, the image is imported via `ImageService` into the `BoxArt/` sandbox directory and attached to the new project.

---

## 4. Interaction Design

### 4.1 Navigation Structure

```
Warmaster Studio
├── Kanban Board (Home — default view)
│   └── Toolbar: "Manage Stages" → ManageStagesSheet (pipeline config)
├── Progress Dashboard
├── Collections (sidebar list for filtering)
├── Image Library (sidebar section)
│   ├── Game System selector
│   ├── Faction chip filter (wrap layout)
│   ├── Image grid with lightbox
│   ├── Move to Faction (context menu)
│   └── Create Project from Image (hover button → sheet)
├── Recipe Library (Phase 2)
└── Paint Library (Phase 2)
```

The app uses a standard macOS three-panel layout where appropriate:
- **Sidebar:** Navigation (Kanban, Progress, Collections, Libraries)
- **Content area:** Primary view (Kanban board, dashboard, etc.)
- **Inspector/detail panel:** Project detail, recipe detail (slides in from right as needed)

---

### 4.2 Empty States

| State | Message |
|---|---|
| No projects | "No projects yet. Create a project to get started." + CTA button |
| No models at a stage | Column is visible but empty (no cards shown) |
| No collection filter match | "No projects in this collection." |
| No recipes | "No recipes yet. Add a recipe from a project's detail view." |

---

### 4.3 Keyboard Shortcuts (MVP)

| Action | Shortcut |
|---|---|
| New Project | ⌘N |
| Open Settings | ⌘, |
| Focus search / filter | ⌘F |
| Close inspector/popover | Escape |

---

### 4.4 Drag and Drop Details

- Cards are draggable within the Kanban board.
- Valid drop targets: stage column headers or the column body.
- Dropping onto the source column is a no-op (no visual error needed).
- Invalid drop targets should provide visual feedback (e.g. a muted drop indicator).
- macOS drag and drop uses `NSItemProvider` / SwiftUI `.draggable()` and `.dropDestination()` APIs.

---

## 5. Tech Stack

### 5.1 Platform Requirements

| Requirement | Value |
|---|---|
| Platform | macOS only (Phase 1–2) |
| Minimum macOS version | macOS 14 Sonoma |
| UI Framework | SwiftUI |
| Language | Swift 5.9+ |

### 5.2 Persistence

**SwiftData** is used for all local persistence.

Key modelling notes:
- All entities described in §2 map to `@Model` classes.
- Relationships use SwiftData's relationship annotations (`@Relationship`) with appropriate delete rules.
- The global Pipeline singleton can be fetched with a fixed query (expect exactly one result; create on first launch if absent).
- `ModelRecord` arrays may be large for big collections; queries should be scoped to avoid loading all records unnecessarily.
- Stage deletion is guarded at the service layer: any attempt to delete a Stage with associated ModelRecords must throw an error before SwiftData is asked to perform the delete.

### 5.3 CloudKit Sync (Phase 3)

- SwiftData supports CloudKit sync via `ModelConfiguration` with a CloudKit container.
- This is deferred to Phase 3.
- Data model should be designed with CloudKit compatibility in mind from the start:
  - All relationships should be optional or have sensible defaults (CloudKit sync is eventual-consistency).
  - Avoid non-optional relationships that could cause sync conflicts.
  - UUIDs as primary keys (already specified above).
- Box art images are **excluded from CloudKit sync** — they are local-only files in the app sandbox. Only `boxArtImagePath` (the path string) is stored in SwiftData; if sync is added in Phase 3, image transfer will need a separate strategy (e.g. CloudKit assets or a separate file sync mechanism).

### 5.4 Image Handling

**Box art (project-level):**
- Stored as files in `~/Library/Application Support/com.warmasterstudio.app/BoxArt/`.
- On attachment, the source image is copied into `BoxArt/`; the original is not modified.
- `Project.boxArtImagePath` stores the relative path from the sandbox root to the copied file.
- Full-size lightbox is available from the project detail view (overlay-based, not a separate window).

**Image Library:**
- Stored in `~/Library/Application Support/com.warmasterstudio.app/ImageLibrary/{System}/{Faction}/`.
- Scanned at runtime by `ImageLibraryService` which walks the directory tree two levels deep (system → faction → files).
- Images are never bundled in the app binary; the library folder persists independently of the app.
- Moving an image to a different faction renames/moves the file on disk; no database entry is maintained — the folder structure *is* the index.

**General:**
- Images are loaded on demand using `NSImage(contentsOfFile:)` and are not held in memory permanently.
- Displayed using SwiftUI `Image` with `.resizable()` and `.aspectRatio(contentMode: .fit)`.

### 5.5 No Third-Party Dependencies (MVP)

The MVP should have zero third-party dependencies. All functionality is achievable with:
- SwiftUI
- SwiftData
- Foundation
- UniformTypeIdentifiers (for drag/drop)
- AppKit (where SwiftUI falls short for macOS-specific behaviour)

---

## 6. Roadmap & Phasing

### Phase 1 — MVP

**Goal:** A fully functional Kanban-based project tracker.

**In scope:**

- Global pipeline configuration (add, remove, rename, reorder stages)
- Stage deletion blocked when models are present
- Projects (units) with fixed model count, optional collection, notes, and optional link group
- Linked project grouping on the Kanban board
- ModelRecord-level progress tracking
- Kanban home screen with:
  - Columns per stage
  - Cards per project-stage combination
  - Drag-and-drop card movement
  - + / − model buttons
  - Linked project visual grouping
- Collection management (create, rename, delete)
- Basic progress view: unit count and model count per stage, filterable by collection

**Out of scope for Phase 1:**
- Box art images and recipe pins
- Paint recipe library
- Paint library (catalogue and My Paints)
- Image Library
- CloudKit sync
- iOS app

---

### Phase 2 — Recipes, Enrichment & Image Library

**Goal:** Add paint recipe documentation, richer project detail, and the Image Library.

**In scope:**

- Box art image attachment per project (stored as local file; path in SwiftData)
- Full-size lightbox viewer for box art in project detail
- Recipe pin placement on box art image with popover UI
- Paint recipe library (create, edit, reuse recipes)
- Paint library: pre-seeded catalogue + My Paints (searchable autocomplete for recipe steps)
- Richer progress dashboard (charts, percentage breakdowns)
- **Image Library** — browse GW product images by game system and faction
  - Faction chip filter with wrap layout (multiple rows for narrow windows)
  - Lightbox viewer with previous/next navigation
  - Move to Faction via right-click context menu
  - Create Project from Image (auto-fills name, collection, box art)

---

### Phase 3 — Platform Expansion (Future)

**Goal:** Sync and reach.

**In scope:**

- iCloud sync via CloudKit (metadata only; image sync strategy TBD)
- iOS companion app (read and update Kanban state on iPhone/iPad)
- Statistics and velocity tracking (time per stage, painting rate, projected completion date)

---

## Appendix A — Glossary

| Term | Definition |
|---|---|
| **Pipeline** | The global ordered sequence of stages that all projects move through |
| **Stage** | One step in the pipeline; one column in the Kanban board |
| **Project** | A unit type being painted (e.g. "Intercessor Squad") |
| **ModelRecord** | Tracks the stage of one individual model within a project |
| **Card** | A Kanban board card representing all models of one project at one stage |
| **Link group** | A set of projects sharing a `linkGroupId`, visually grouped together on the Kanban |
| **Collection** | A user-defined grouping of projects (army, warband, display shelf, etc.) |
| **PaintRecipe** | An ordered list of paint steps for a named surface area |
| **RecipePin** | A pin placed on a box art image linking a surface area label to a PaintRecipe |
| **Paint** | An entry in the paint database — either from the seeded catalogue or from My Paints |
| **Image Library** | A local folder of Games Workshop product images organised by game system and faction, stored in Application Support |
| **Move to Faction** | Recategorising a library image by moving its file to a different faction subfolder on disk |

---

## Appendix B — Open Questions

All design questions have been resolved as of v1.4. No open questions remain.

| # | Question | Resolution | Version |
|---|---|---|---|
| 1 | Stage deletion with existing models | Blocked — deletion is prevented until all models are moved out of the stage | v1.3 |
| 2 | Model count mutability | Fixed at creation. Users create a new project for additional models and optionally link it to the original | v1.3 |
| 3 | Sub-stage / checklist gate | Removed entirely. The pipeline is flat; models move between stages with no intermediate gates | v1.3 |
| 4 | Box art image storage | External file in app sandbox; SwiftData stores the path only | v1.3 |
| 5 | Recipe pin UI | Popover anchored to pin, showing ordered paint steps with swatch, name, brand, type, and technique | v1.3 |
| 6 | Battlescribe import | Removed from roadmap — out of scope | v1.3 |
| 7 | Pre-seeded paint library — read-only vs. editable | Seeded catalogue is read-only; "My Paints" is a separate fully editable section | v1.2 |
| 8 | Pipeline config location | Moved from Settings window (removed) to Manage Stages sheet in Kanban toolbar | v1.4 |
| 9 | Image Library storage — bundled vs. Application Support | Images stored in Application Support; not bundled in app binary. Persists across reinstalls. | v1.4 |
| 10 | Image Library index — database vs. filesystem | Filesystem is the index. Folder structure (System/Faction/file) is authoritative; no SwiftData model needed. | v1.4 |
