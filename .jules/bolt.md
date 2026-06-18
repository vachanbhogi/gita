
## 2024-05-24 - Single Pass Over Iterators - Performance
- **Learning**: Multiple array passes (`filter`, `min`, `firstIndex`) lead to intermediate array allocations and O(N) operations. Combine these checks into a single loop pass to keep it strictly O(N) with O(1) space.
- **Action**: Applied single pass technique in `BrowserEngine.swift`'s `enforceLRULimit` to calculate active tab counts and locate the oldest background tab index in one enumeration.
