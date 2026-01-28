# Palette's Journal

## 2024-05-22 - Anti-pattern: GestureDetector on Icons
**Learning:** Found widespread use of `GestureDetector` wrapping `Icon` widgets (often with `MouseRegion` and `Tooltip`). This pattern fails to provide native button semantics, accessibility traits (like button role), and interaction feedback (ink ripples).
**Action:** Replace with `IconButton` which handles tooltips, semantics, and visual feedback natively. This significantly improves accessibility with minimal code changes.
