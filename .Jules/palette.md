# Palette's Journal

This journal documents critical UX and accessibility learnings from the `cash_records` project.

## 2023-10-27 - Anti-pattern: Manual Icon Buttons
**Learning:** Found a recurring anti-pattern where icon buttons were built manually using `MouseRegion` > `Tooltip` > `GestureDetector` > `Icon`. This manually reimplements button behavior but often misses accessibility features like proper semantic roles, keyboard focus, and ink splash effects.
**Action:** Replace these manual compositions with the standard `IconButton` widget, which provides `tooltip`, `onPressed`, and correct accessibility semantics out of the box.
