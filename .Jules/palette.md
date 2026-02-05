## 2024-02-12 - Icon Accessibility Anti-Pattern
**Learning:** The codebase frequently wraps `Icon` in `GestureDetector` instead of using `IconButton`. This breaks accessibility semantics and keyboard focus.
**Action:** Proactively scan for `GestureDetector(child: Icon(...))` patterns and refactor to `IconButton` to gain native accessibility and ripple effects.
