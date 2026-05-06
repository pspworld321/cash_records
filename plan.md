1. **Refactor `lib/driveSync.dart` to use `google_sign_in`**
   - Replace the outdated browser-based auth flow (`clientViaUserConsent`) with the native Google Sign-In SDK (`google_sign_in`).
   - Use `extension_google_sign_in_as_googleapis_auth` to securely bridge `GoogleSignIn` accounts to a `googleapis` authenticated HTTP client.
   - Add a `restoreSession()` method that uses `signInSilently()` to try to restore existing sessions without forcing interactive popups.
   - Replace `authenticate()` to explicitly call `signIn()` when needed.
   - Remove redundant manual token caching (`saveCredentials`, `getCredentials`, `refreshTheToken`) since `google_sign_in` handles session persistence natively.
   - Update `clearCredentials()` to call `signOut()` and `disconnect()` on the `GoogleSignIn` instance.
2. **Update App Startup in `lib/main.dart`**
   - Replace the manual `getCredentials()` check in `main()` with a call to the new `driveSync.restoreSession()` method to silently establish an authenticated drive client if the user was previously logged in.
3. **Pre-commit checks**
   - ensure proper testing, verification, review, and reflection are done.
4. **Submit changes**
