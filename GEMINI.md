# Project Rules & Development Workflow

## 1. Bug Reporting and Code Modification Protocol
Whenever a bug is identified or reported by the user:
1. **Explain the Bug First**: Clearly describe what the bug is, where it occurs, and why it is happening.
2. **Propose the Solution**: Detail the potential solution(s) and how it will fix the issue without side effects.
3. **Wait for User Approval**: **STOP and WAIT** for the user's explicit approval before editing or modifying any code.
   - **DO NOT** make code modifications proactively for bugs until the user confirms and approves the approach.

## 2. Build Generation Policy
- **DO NOT** generate or trigger APK builds (`flutter build apk`, release or debug builds) automatically.
- Only run build commands when the user **explicitly requests a build** (e.g., "build apk", "apk bana do", "make release build").

## 3. Communication Style
- Always communicate and provide explanations in English.
- Keep explanations clear, structured, and concise.
