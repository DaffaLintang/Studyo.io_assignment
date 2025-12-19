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

## Project Structure

```
lib/
├── app/
│   ├── modules/
│   │   └── home/
│   │       ├── bindings/
│   │       ├── controllers/
│   │       └── views/
│   ├── routes/
│   └── widgets/
└── main.dart
```

## Features

- Interactive marble-based puzzle interface
- Color-based counting and validation
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
