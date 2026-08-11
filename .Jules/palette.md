## 2026-01-23 - Accessibility Pattern: Interactive Icons
**Learning:** This app frequently used `GestureDetector` wrapping an `Icon` for interactive elements. This pattern lacks accessibility features like semantic roles, keyboard focus, and visual feedback (ink ripples).
**Action:** Use `IconButton` instead of `GestureDetector` + `Icon`. It provides built-in accessibility (semantics, focus), ripple effects, and tooltip support. If custom sizing is needed, `IconButton` supports `iconSize`.
