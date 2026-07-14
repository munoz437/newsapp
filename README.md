# newsapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

comando para ejecutar con api key

flutter run --dart-define=NEWS_API_KEY=d4c19d76827f4659a8e59b05eb30d002

flutter run -d emulator-5554


Comando para crear el apk:

flutter build apk --release --dart-define=NEWS_API_KEY=d4c19d76827f4659a8e59b05eb30d002

flutter build apk --release --dart-define-from-file=dart_define.json

