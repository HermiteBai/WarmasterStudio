# Warmaster Studio

A native macOS app for hobbyists who paint Warhammer miniatures. Track painting projects from raw sprues to completion, manage paint recipes, and browse your Games Workshop image library — all in one place.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **Kanban board** — track every model across your custom pipeline stages
- **Project management** — create units with fixed model counts, group them into collections, and link related projects
- **Paint recipes** — pin recipes directly onto box art images with per-step colour swatches
- **Image Library** — browse Games Workshop product images by game system and faction; create projects directly from an image
- **Progress dashboard** — see model counts per stage, filterable by collection
- **Manage Stages** — add, rename, reorder, and delete pipeline stages from the Kanban toolbar

---

## Requirements

- macOS 14 Sonoma or later
- Xcode 15 or later (to build from source)

---

## Installation

### Option A — Download the DMG

1. Go to the [Releases](https://github.com/HermiteBai/WarmasterStudio/releases) page
2. Download the latest `WarmasterStudio.dmg`
3. Open the DMG and drag **WarmasterStudio.app** into your `/Applications` folder
4. Launch the app

> **Note:** The app is unsigned. On first launch, macOS may block it. Go to **System Settings → Privacy & Security** and click **Open Anyway**.

### Option B — Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/HermiteBai/WarmasterStudio.git
   cd WarmasterStudio
   ```

2. Open the project in Xcode:
   ```bash
   open WarmasterStudio.xcodeproj
   ```

3. Select the **WarmasterStudio** scheme and your Mac as the run destination, then press **⌘R** to build and run.

   Or build from the command line:
   ```bash
   xcodebuild -project WarmasterStudio.xcodeproj \
              -scheme WarmasterStudio \
              -configuration Debug \
              build
   ```

---

## Image Library Setup

The Image Library is not bundled with the app — images are stored in Application Support and persist across reinstalls.

To populate the library, place images into this folder structure:

```
~/Library/Application Support/com.warmasterstudio.app/ImageLibrary/
  {Game System}/
    {Faction}/
      image.jpg
```

For example:
```
ImageLibrary/
  Warhammer 40,000/
    Space Marines/
      Intercessors.jpg
  Age of Sigmar/
    Stormcast Eternals/
      Liberators.jpg
```

Relaunch the app after adding images — the library scans on launch.

---

## Data & Privacy

All data is stored locally on your machine:

| Data | Location |
|---|---|
| Projects, collections, stages | `~/Library/Application Support/com.warmasterstudio.app/` |
| Box art images | `~/Library/Application Support/com.warmasterstudio.app/BoxArt/` |
| Image Library | `~/Library/Application Support/com.warmasterstudio.app/ImageLibrary/` |

No data is sent to any server. No accounts required.

---

## Tech Stack

- **SwiftUI** — native macOS UI
- **SwiftData** — local persistence
- **Zero third-party dependencies**

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to get started.

---

## License

MIT — see [LICENSE](LICENSE) for details.
