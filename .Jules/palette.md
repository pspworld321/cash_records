# Palette's Journal

## 2023-10-27 - [Anti-Pattern: GestureDetector vs IconButton]
**Learning:** Found widespread use of `GestureDetector` + `Icon` + `MouseRegion` + `Tooltip` to simulate buttons. This hurts accessibility (missing roles, focus) and maintainability.
**Action:** Replace with `IconButton` which bundles these behaviors correctly.
