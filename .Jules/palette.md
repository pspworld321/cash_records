## 2024-05-22 - Flutter Clear Button Pattern
**Learning:** TextEditingController.clear() does not trigger onChanged, causing search lists to not update when cleared.
**Action:** Always manually trigger state update or listener notification when programmatically clearing a controller.
