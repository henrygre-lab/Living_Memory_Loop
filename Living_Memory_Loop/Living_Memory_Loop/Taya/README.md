# Taya Swift Scaffold (Milestone 0)

This folder contains the coding scaffold for Milestone 0 of the Swift conversion:

- App entry: `TayaApp.swift`
- Folder structure: `Models/`, `Services/`, `Views/`, `Helpers/`, `Resources/Fonts/`
- `MemoryStore` environment injection shell
- Placeholder `HomeScreen` with Inter font references and ocean-blue colors
- `Info.plist` template with microphone permission and `UIAppFonts`

## Xcode wiring

1. Create a new iOS SwiftUI app target named `Taya` (iOS 17+).
2. Add all files in this folder to the target.
3. Add Inter `.ttf` files under `Resources/Fonts/` and ensure they are target members.
4. Point the target to `Taya/Info.plist` (or copy its keys into your existing plist).

After this, the app should launch to the placeholder home screen with the configured color and typography setup.
