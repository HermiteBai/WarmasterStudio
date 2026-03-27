# Contributing to Warmaster Studio

Thanks for your interest in contributing! This is a native macOS app built with SwiftUI and SwiftData, with zero third-party dependencies.

---

## Getting Started

### Prerequisites

- macOS 14 Sonoma or later
- Xcode 15 or later
- Swift 5.9 or later

### Setup

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/WarmasterStudio.git
   cd WarmasterStudio
   ```
3. Open the project:
   ```bash
   open WarmasterStudio.xcodeproj
   ```
4. Build and run with **⌘R** to confirm everything works

---

## Project Structure

```
Sources/WarmasterStudio/
  Models/             SwiftData @Model types (Project, Stage, Pipeline, etc.)
  Services/           Business logic (ProjectService, ImageService, ImageLibraryService, etc.)
  Views/
    AppShell/         ContentView, sidebar, navigation
    Kanban/           Kanban board and cards
    Projects/         Project detail, creation sheets
    Library/          Image Library, lightbox, CreateProjectFromImageSheet
    Collections/      Collection management
    Dashboard/        Progress dashboard
    Pins/             Box art canvas and recipe pin popovers
    Recipes/          Paint recipe library
    PaintLibrary/     Paint catalogue and My Paints
Docs/
  warmaster-studio-requirements.md   Product requirements (v1.4)
  warmaster-studio-workplan.md       Development work plan (v1.1)
```

---

## How to Contribute

### Reporting Bugs

Open a [GitHub Issue](https://github.com/HermiteBai/WarmasterStudio/issues) with:
- macOS version
- Steps to reproduce
- Expected vs. actual behaviour
- Screenshots or crash logs if applicable

### Suggesting Features

Open a GitHub Issue tagged `enhancement`. Check the [work plan](Docs/warmaster-studio-workplan.md) first — it outlines what is planned for each phase.

### Submitting a Pull Request

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
2. Make your changes, keeping each PR focused on one concern
3. Test on macOS 14 Sonoma (minimum supported version)
4. Push and open a PR against `main` with a clear description of what changed and why

---

## Code Guidelines

- **No third-party dependencies.** Everything must be achievable with SwiftUI, SwiftData, Foundation, AppKit, or UniformTypeIdentifiers.
- **SwiftData for persistence.** Do not introduce CoreData, SQLite, or file-based JSON stores for app data.
- **macOS 14+ APIs only.** Do not use APIs unavailable on macOS 14 Sonoma.
- **No force unwraps** in new code. Use `guard`, `if let`, or `try?` with a fallback.
- Follow the existing file and type naming conventions — Views end in `View` or `Sheet`, services end in `Service`.
- Keep views small. Extract subviews and helpers rather than building monolithic view bodies.

---

## Architecture Notes

A few non-obvious decisions worth knowing before diving in:

- **Multiple `.sheet` modifiers** on macOS SwiftUI only work if each is attached to a different view node. Attach sheets directly to their trigger button/view, not to the top-level `body`.
- **`GeometryReader` breaks intrinsic height.** Use the `Layout` protocol (`WrapLayout`) for custom flow layouts instead.
- **`StageHistoryEntry` uses a denormalised `projectId` UUID** with no cascade relationship — deleting a project requires manually deleting its history entries in `ProjectService`.
- **Image Library is filesystem-based.** The folder structure (`System/Faction/file`) is the index — there is no SwiftData model for library images.
- **Box art is stored in Application Support**, not the app bundle. Path stored in `Project.boxArtImagePath`.

---

## Running Tests

```bash
xcodebuild test \
  -project WarmasterStudio.xcodeproj \
  -scheme WarmasterStudio \
  -destination 'platform=macOS'
```

---

## Questions?

Open a GitHub Issue or start a Discussion. All feedback is welcome.
