# Gita

Gita is a native macOS browser-like app built with SwiftUI and SwiftData, with Rust-based ad-blocking support via UniFFI.

## Project structure

- `gita/` — macOS app source code and Xcode project
- `Rust/gita_adblock/` — Rust crate exposing a native ad-block engine via UniFFI
- `Rust/gita_adblock_compile/` — Rust helper for compiling ad-block filter resources
- `gita.xcodeproj/` — Xcode project file for the `Gita` app

## Requirements

- macOS with Xcode installed (the project uses macOS deployment target `27.0`)
- Rust toolchain installed via `rustup` (`cargo` available on `PATH`)

## Build overview

The Xcode project includes a shell build phase that compiles the Rust ad-block library before building the Swift app. The script does:

```sh
cd "${SRCROOT}/Rust"
cargo build --release -p gita_adblock
```

That produces:

- `Rust/target/release/libgita_adblock.dylib`

The Swift app loads this library through the generated UniFFI Swift bindings in `gita/AdBlock/FFI/gita_adblock.swift`.

## Running the app

### Option 1: Open in Xcode

1. Open `gita/gita.xcodeproj` in Xcode.
2. Select the `gita` macOS target.
3. Build and run.

### Option 2: Command line

From the repository root:

```sh
cd gita
xcodebuild -project gita.xcodeproj -scheme gita -configuration Debug -destination 'platform=macOS'
```

If Xcode cannot find the active developer directory, install the full Xcode app and set it with:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Manual Rust build

If you want to build the Rust library separately, run from the repository root:

```sh
cd Rust
cargo build --release -p gita_adblock
```

If the Xcode build fails because `cargo` is unavailable, install Rust:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Features

- SwiftUI-based macOS browser UI
- Tab management and keyboard shortcuts
- Bookmarks and history support
- Ad-blocking powered by a Rust engine via UniFFI
- Content rule installation and site-level shield controls

## Notes

- The app uses SwiftData for local browser data persistence.
- Ad-block resource files are located under `gita/Resources/AdBlock`.
- The Rust library is referenced in the Xcode project as a `.dylib` output from the Rust build.

## Keyboard shortcuts

The app exposes several macOS keyboard shortcuts in the app menus:

- Command + T — New tab
- Command + W — Close tab
- Command + L — Focus location/address bar
- Command + [ — Go back
- Command + ] — Go forward
- Command + R — Reload page
- Command + Shift + B — Show bookmarks
- Command + Y — Show history
- Command + Shift + E — Toggle shields
- Command + 1..9 — Switch to numbered tabs

## Getting started

1. Open `gita/gita.xcodeproj` in Xcode.
2. Build and run the `gita` macOS target.
3. Use the toolbar and address bar to navigate, or use the keyboard shortcuts above.

## Troubleshooting

- If build fails with `Rust toolchain not found`, ensure `cargo` is installed and available in Xcode’s shell environment.
- If the app does not load the Rust library, verify `Rust/target/release/libgita_adblock.dylib` exists.
- If you need to rebuild after a dependency change, clean the Xcode build folder and rerun the build.
