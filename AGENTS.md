# AGENTS.md

This file provides a comprehensive guide for AI agents working on the CV Builder project. It details the architecture, authentication flow, data structures, and development guidelines.

## 🚀 Project Overview
**CV Builder** is a Flutter-based mobile application designed to help users create ATS-optimized CVs.
- **Core Stack**: Flutter, Firebase (Auth & Firestore), Provider (State Management).
- **Key Features**: Google Sign-In, Multi-template PDF generation, Cloud sync, Account management.

## 🏗️ Project Architecture
The project follows a modular, layered architecture to ensure scalability and maintainability:

- **`lib/models/`**: Defines data structures (e.g., `CVModel`, `UserModel`, `Experience`, `Education`).
- **`lib/services/`**: Abstracts external infrastructure.
  - `AuthService`: Handles Firebase and Google authentication.
  - `FirestoreService`: Manages CRUD operations for users and CVs.
  - `AccountDeletionService`: Logic for secure data removal.
- **`lib/providers/`**: Manages application state using the **Provider** package.
  - `CVProvider`: Tracks the current CV being edited and the list of user CVs.
- **`lib/screens/`**: UI components organized by feature (Auth, Home, CV Builder, Preview).
- **`lib/widgets/`**: Shared, reusable UI components.
- **`lib/config/`**: App-wide constants, themes, and ATS guidelines.

## 🔐 Authentication (Modern Google Sign-In)
The application uses a modern implementation of Google Sign-In for improved performance and security.

### Key Implementation Details:
1. **Initialization**: `AuthService.initializeGoogleSignIn(serverClientId: ...)` **must** be called in `main.dart` before `runApp`.
2. **Modern Flow**: 
   - Uses `_googleSignIn.authenticate()` (replaces the older `signIn()`).
   - Authentication details are retrieved synchronously from the `GoogleSignInAccount` object.
   - Firebase sign-in only requires the `idToken`.
3. **Workflow**:
   ```dart
   final googleUser = await _googleSignIn.authenticate();
   final googleAuth = googleUser.authentication;
   final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
   await _auth.signInWithCredential(credential);
   ```

## 💾 Data Management (Firestore)
- **Users**: Profile data is stored in the `users` collection.
- **CVs**: Stored in a sub-collection for each user: `users/{userId}/cvs/{cvId}`.
- **ATS Optimization**: CVs are structured to follow ATS guidelines, with dedicated sections for keywords and clear metadata.

## 📱 Navigation & Screen Flow
1. **Splash/Onboarding**: Initial entry and app introduction.
2. **Auth Wrapper**: `AuthWrapper` in `main.dart` uses a `StreamBuilder` to listen to `authStateChanges` and direct the user to the `HomeScreen` (if logged in) or `LoginScreen`.
3. **Home**: Dashboard displaying existing CVs fetched via `FirestoreService.getUserCVs`.
4. **CV Builder**: A multi-step process (Personal Info → Summary → Education → Experience → Skills → Projects → Template Selection).
5. **Preview**: Uses the `pdf` and `printing` packages to generate and display the final document.

## 🛠️ Build & Release
- **Signing**: Uses `upload-keystore.jks` (located in the root directory) for release builds.
- **Keystore Config**: Managed via `android/key.properties`. Ensure the path to the keystore is correct relative to the `android/app` directory.
- **Command**: `flutter build apk --release`.

## 📏 Coding Standards & Linting
- **Naming**: `PascalCase` for classes, `camelCase` for methods/variables.
- **Types**: Explicit types are preferred over `var`. Null safety must be strictly followed.
- **Linting**: Run `flutter analyze` to ensure code quality. Rules are defined in `analysis_options.yaml`.
- **Formatting**: Use `flutter format .` before committing changes.
- **Imports**: Organize imports with standard Flutter packages first, then third-party packages, then project-specific files, separated by blank lines.

## 🧪 Testing
- **Command**: `flutter test` runs all widget and unit tests.
- **Widget Tests**: Located in the `test/` directory, using `WidgetTester` for interactions.

## ⚠️ Non-Obvious Conventions
- **PDF Generation**: Does not use Flutter widgets directly; it uses the `pdf` package's specific API to build documents.
- **Route Constants**: Routes are defined centrally in `AppRoutes`. Always use these constants for navigation.
- **Firebase Initialization**: `Firebase.initializeApp()` must complete before any other Firebase-related code execution.