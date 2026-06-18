## 2024-06-16 - Add Tooltips to Icon-Only Buttons
**Learning:** Icon-only buttons (like nav controls and tab close buttons) lack accessible labels by default in SwiftUI.
**Action:** Always add `.help("Tooltip text")` to icon-only `Button` elements. This provides both a visual tooltip on hover and a standard accessibility label for screen readers on macOS.
## 2026-06-17 - Adding Tooltips to Icon-Only SwiftUI Buttons
**Learning:** In macOS SwiftUI apps, icon-only buttons often lack discoverability and accessibility labels. Using the `.help()` modifier provides a simple, native way to add both hover tooltips and screen reader accessibility labels simultaneously.
**Action:** Always add an optional tooltip property to custom button components (like `ChromeButton`) and conditionally apply `.help()` to improve UX and a11y.
