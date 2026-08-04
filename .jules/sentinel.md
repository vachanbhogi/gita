## 2024-05-24 - Fix gita:// scheme abuse
**Vulnerability:** Untrusted web content could trigger internal `gita://reload` actions via JavaScript or iframes.
**Learning:** Internal application URL schemes should not be exposed to untrusted content without strict validation of the current tab/application state.
**Prevention:** Always validate the tab state (e.g., `.failed`) before executing internal actions triggered by custom schemes in `decidePolicyFor`.
