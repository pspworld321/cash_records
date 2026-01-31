# Palette's Journal

## 2024-05-22 - Search Interaction & State Sync
**Learning:** In Flutter, `TextEditingController.clear()` does NOT trigger `onChanged` callbacks on the `TextFormField`. This is a common trap that leads to state desynchronization (UI clears, but search filter remains active). Always manually trigger the state update or listener when programmatically changing text.
**Action:** When adding "Clear" buttons to inputs, always verify that the state update logic (e.g., `setState`, `ValueNotifier` update) is explicitly called, as `onChanged` won't fire.
