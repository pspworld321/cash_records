## 2024-05-22 - Replacing GestureDetector with IconButton
**Learning:** `GestureDetector` on icons lacks keyboard focus, semantic information, and visual feedback (ink splash) which are critical for accessibility. `IconButton` provides these out of the box.
**Action:** When making icons clickable, always prefer `IconButton` over `GestureDetector` unless a very specific custom behavior is needed.
