## 2023-10-27 - [Avoid String Allocations in Search Filters]
**Learning:** Using `.lowercased().contains()` in `SwiftUI` `filter` closures creates significant memory churn by allocating a new `String` for every record checked on every keystroke. For large lists like history and bookmarks, this can cause stuttering during search.
**Action:** Replace `.lowercased().contains(query)` with `.localizedStandardContains(query)`. This Apple-recommended method avoids creating intermediate strings and is highly optimized for user-facing search.
