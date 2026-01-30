## 2024-05-22 - Accessibility Anti-patterns
**Learning:** This codebase heavily relies on `GestureDetector` wrapped around `Icon` (often with `MouseRegion` and `Tooltip`) for interactive elements instead of using semantic buttons like `IconButton`. This hurts accessibility by removing standard button traits (semantics, keyboard focus, ink effects).
**Action:** Systematically replace these patterns with `IconButton` or `TextButton` where appropriate, ensuring tooltips are preserved.
