## 2024-06-16 - Add Tooltips to Icon-Only Buttons
**Learning:** Icon-only buttons (like nav controls and tab close buttons) lack accessible labels by default in SwiftUI.
**Action:** Always add `.help("Tooltip text")` to icon-only `Button` elements. This provides both a visual tooltip on hover and a standard accessibility label for screen readers on macOS.
