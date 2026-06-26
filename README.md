# Rekty AI

A modern AI assistant built with Flutter and powered by **Pollinations AI**.

## Features

- AI Chat
- AI Image Generation
- AI Image Editing
- Vision
- Prompt Enhancement
- Image Director
- Multiple AI Models
- Multiple Languages
- Chat History
- Image History
- Favorite Images
- Markdown Rendering
- Syntax Highlighting
- Dark Theme

## Technology

- Flutter
- Dart
- Pollinations AI
- Pollination API
- Isar Database
- Provider
- HTTP

## Architecture

```text
Flutter UI
     │
     ▼
Rekty AI Services
     │
     ▼
Pollinations AI
     │
     ▼
AI Models
```

## Requirements

- Flutter 3.32.x+
- Java 17
- Android SDK 35+

## Installation

```bash
git clone <repository-url>
cd rekty_ai
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Release

```bash
flutter build apk --release
```

or

```bash
flutter build appbundle --release
```

## Project Structure

```text
lib/
├── models/
├── screens/
├── services/
├── widgets/
└── main.dart
```

## Powered by Pollinations AI

Rekty AI uses Pollinations AI for AI Chat, Image Generation, Image Editing and Vision.

## Roadmap

- Streaming Responses
- Stop Generation
- Regenerate
- Search History
- Voice Chat
- Local Image Models

## Screenshots

Place screenshots in:

```text
screenshots/
├── chat.png
├── image.png
├── history.png
└── settings.png
```

## License
## contact

Developer: **Rekty Anjany**
Email: rekty.anjany@gmail.com

---

<p align="center">
  <a href="https://pollinations.ai">
    <img src="https://image.pollinations.ai/prompt/pollinations%20ai%20logo%20white%20flower%20minimal?width=120&height=120&model=flux&nologo=true" alt="pollinations.ai Logo White" height="48"/>
  </a>
  <br/>
  <sub>Powered by <a href="https://pollinations.ai">pollinations.ai</a></sub>
</p>

## Screenshots

| Chat | Image Generator |
|------|-----------------|
| ![](screenshots/chat.png) | ![](screenshots/image.png) |

| History | Settings |
|---------|----------|
| ![](screenshots/history.png) | ![](screenshots/settings.png) |
