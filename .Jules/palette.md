## 2024-05-22 - Search Clear Button Logic
**Learning:** `TextEditingController.clear()` does not trigger the `onChanged` callback of a `TextField`. This is a common pitfall when implementing "Clear" buttons, often resulting in the search query being cleared visually but the search results remaining filtered.
**Action:** Always manually trigger the search/filter logic or notify listeners (e.g., `setState`, `ValueNotifier`) immediately after calling `controller.clear()`.
