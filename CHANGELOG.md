## 1.0.0-nullsafety.0
- Migrate to null safety.

## 0.2.0
- Errors are now being sent back to the main process.
- Removed `hasResponseOverride` from IsoxCommand and add explicit `wait`. (This **breaks the default behavior** for void returning commands!)
- Add command not found exception. (Will be thrown when trying to run an unregistered command)
- Restrict commands to the same state type for `IsoxInstance.run`.

## 0.1.0
- Initial release with basic functionality.
