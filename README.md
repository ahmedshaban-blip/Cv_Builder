# CV Builder
[![Ask DeepWiki](https://devin.ai/assets/askdeepwiki.png)](https://deepwiki.com/ahmedshaban-blip/Cv_Builder)

CV Builder is a cross-platform application built with Flutter, designed to help users create, manage, and export professional, Applicant Tracking System (ATS)-friendly résumés. It leverages Firebase for secure authentication and real-time data synchronization, ensuring a seamless user experience across devices.

## Key Features

*   **Step-by-Step CV Builder**: A guided, multi-step process to input Personal Info, Summary, Education, Experience, Skills, and Projects.
*   **ATS-Optimized Templates**: Choose between 'Classic' and 'Modern' templates designed for optimal parsing by ATS software.
*   **Real-time PDF Preview**: Instantly preview your CV as you build it and see how your final document will look.
*   **Firebase Backend Integration**:
    *   Secure user authentication with Email/Password and Google Sign-In.
    *   Cloud Firestore to save and sync multiple CVs for each user, accessible from any device.
*   **Account & Data Management**: A secure flow for users to permanently delete their account and all associated data.
*   **Export & Share**: Download your CV as a PDF or share it directly from the app.

## Tech Stack

*   **Framework**: Flutter
*   **Backend**: Firebase (Authentication, Cloud Firestore)
*   **State Management**: Provider
*   **PDF Generation**: `pdf` & `printing`
*   **Forms**: `reactive_forms` & Standard Flutter Forms
*   **Authentication**: `google_sign_in`

## Project Structure

The project follows a modular architecture for scalability and maintainability.

```
lib/
├── app/          # App configuration, routes
├── config/       # Themes, constants, ATS guidelines
├── models/       # Data models (CVModel, UserModel, etc.)
├── providers/    # State management (CVProvider)
├── screens/      # UI screens organized by feature (Auth, Home, CV Builder)
├── services/     # Backend services (AuthService, FirestoreService)
├── utils/        # Utility helpers and the PDF generator
└── widgets/      # Reusable common and template widgets
```

## Getting Started

### Prerequisites

*   Flutter SDK (v3.11.3 or higher)
*   A code editor like VS Code or Android Studio

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/ahmedshaban-blip/cv_builder.git
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd cv_builder
    ```
3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

### Firebase Configuration

This project uses Firebase for its backend. To run the app, you must set up your own Firebase project.

1.  Create a new project on the [Firebase Console](https://console.firebase.google.com/).
2.  In your project settings, register a new Android and/or iOS app.
3.  **For Android**:
    *   Download the `google-services.json` file.
    *   Place it in the `android/app/` directory.
4.  **For iOS**:
    *   Download the `GoogleService-Info.plist` file.
    *   Open `ios/Runner.xcworkspace` in Xcode and add the file to the `Runner` target.
5.  In the Firebase Console, enable the following services:
    *   **Authentication**: Enable `Email/Password` and `Google` sign-in providers.
    *   **Firestore**: Create a Firestore database.
6.  **Update Google Sign-In Client ID**:
    *   Open `lib/main.dart` and replace the placeholder `serverClientId` in the `AuthService.initializeGoogleSignIn` call with your Web Client ID from the Google Sign-In provider settings in Firebase.

### Running the App

Once setup is complete, run the application from your terminal:
```sh
flutter run
```

## Building for Production (Android)

The project is configured to use a keystore for generating signed release builds.

1.  Place your `upload-keystore.jks` file in the root directory of the project.
2.  Create a file named `key.properties` in the `android/` directory (note: the repository includes this at `important data/key.properties`, you can move and edit it).
3.  Add your keystore credentials to `android/key.properties`:
    ```properties
    storePassword=<your_store_password>
    keyPassword=<your_key_password>
    keyAlias=upload
    storeFile=../../upload-keystore.jks
    ```
4.  Run the build command:
    ```sh
    flutter build apk --release
