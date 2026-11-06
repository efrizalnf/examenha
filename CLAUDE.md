# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Run app**: `flutter run`
- **Analyze code / lint**: `flutter analyze`
- **Run tests**: `flutter test`
- **Run a single test**: `flutter test test/widget_test.dart`
- **Build APK (Android)**: `flutter build apk`
- **Clean build**: `flutter clean && flutter pub get`

## Architecture & Structure

This is a Flutter application (**ExamForm** / `exam_forms`) following **Clean Architecture** principles, organized into feature modules with `flutter_bloc` for state management and `get_it` for dependency injection.

### Directory Structure (`lib/`)
- `core/`: Global utilities, constants (`AppColors`, `AppConstants`), network clients (`ApiClient`), failure definitions, and shared widgets.
- `features/`: Feature-driven slices, each structured into layers:
  - `data/`: Repositories implementations, local stores, models.
  - `domain/`: Entities, repository interfaces, use cases.
  - `presentation/`: Pages, widgets, and BLoCs (`flutter_bloc`).
- `injection_container.dart`: Centralized `GetIt` service locator configuration (`initDependencies()`).

### Key Technologies
- **State Management**: `flutter_bloc` / `Bloc` / `Cubit`
- **Dependency Injection**: `get_it` (`sl`)
- **Functional/Either**: `dartz`
- **Local Storage**: `flutter_secure_storage`
- **Core Features**: QR Code Scanning (`mobile_scanner`), WebView (`webview_flutter`), Exam CBT integrations (Google / Microsoft Forms via API).
