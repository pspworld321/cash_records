## 2026-01-24 - Accessibility Anti-patterns
**Learning:** Found usage of `GestureDetector` wrapped around `Icon` for interactive elements. This lacks semantic role, keyboard focus, and accessibility traits.
**Action:** Replace such patterns with `IconButton` or `InkWell` (with proper semantics) to ensure accessibility and consistent touch targets. Use `IconButton`'s `tooltip` property for built-in accessibility labeling.
