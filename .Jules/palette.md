## 2024-05-23 - Accessibility Anti-Pattern: GestureDetector + Icon
**Learning:** Using `GestureDetector` wrapped around an `Icon` creates an inaccessible interaction. It lacks semantic role information (screen readers don't know it's a button), focus states, and proper touch target sizing (48x48dp).
**Action:** Replace these instances with `IconButton` which provides built-in accessibility semantics, focus indication, tooltips, and correct touch target size.
