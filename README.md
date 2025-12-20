# Studyo.io Assignment

A Flutter application for managing and solving marble-based puzzles.

## Prerequisites

- Flutter SDK (version 3.9.2 or later)
- Dart SDK (included with Flutter)
- Git
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (recommended IDEs)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/DaffaLintang/Studyo.io_assignment.git
   cd studyo_assignment01
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```
   - For web: `flutter run -d chrome`
   - For Android: Connect an Android device or use an emulator, then run `flutter run`
   - For iOS: `cd ios && pod install && cd ..` then `flutter run`

## Project Structure (Clean Architecture)

```
lib/
├── core/
│   └── domain/
│       ├── entities/
│       │   ├── answer_check_result.dart
│       │   └── assignment.dart
│       └── usecases/
│           └── check_answer_usecase.dart
├── presentation/
│   ├── modules/
│   │   └── home/
│   │       ├── bindings/
│   │       │   └── home_binding.dart
│   │       ├── controllers/
│   │       │   └── home_controller.dart
│   │       └── views/
│   │           └── home_view.dart
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   └── widgets/
│       └── widget/
│           ├── AnswerContainer.dart
│           ├── AppContainer.dart
│           ├── Appbar.dart
│           ├── AssigmentContainer.dart
│           ├── CheckButton.dart
│           ├── MarblePlayground.dart
│           └── marbel.dart
└── main.dart
```

### Layering
- `core/domain`: Pure business rules (entities, use cases). No dependency on UI/framework.
- `presentation`: UI/interaction (GetX controllers, views, routes, widgets). Depends on the domain via dependency injection.
- `infrastructure` (optional, not present yet): where datasource/repository implementations will live if needed later.

## Features

- Interactive marble-based puzzle interface
- Color-based counting and validation (Check Answer)
- Network Radial Layout for marble cluster layout (organic, adaptive)
- Visual connectors between marbles outside the AnswerContainer
- Interactive animations: idle jitter, drag reaction, ripple on merge/unmerge
- Responsive design for multiple platforms

## Dependencies

- `get`: ^4.7.3 - State management and dependency injection
- `cupertino_icons`: ^1.0.8 - For iOS-style icons

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
