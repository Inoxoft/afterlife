# Afterlife - Digital Twin Chat Application

Afterlife is a Flutter application that allows users to create and interact with their digital twins. Create personalized AI avatars through an interview process and then chat with them anytime.

![Afterlife App](screenshots/app_preview.png)

## Features

- **Create Digital Twins**: Go through an interactive interview to create a digital version of yourself
- **Character Gallery**: View and manage all your created digital twins
- **Chat Interface**: Chat with your digital twins using a modern, responsive UI
- **Persistent Storage**: Your characters and chat history are saved locally
- **API Integration**: Powered by advanced language models via OpenRouter API

## Getting Started

### Prerequisites

- Flutter 3.0+
- Dart 2.17+

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/afterlife.git
   ```

2. Navigate to the project directory
   ```
   cd afterlife
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Create a `.env` file in the root directory with your API keys
   ```
   OPENROUTER_API_KEY=your_api_key_here
   ```

5. Run the app
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── core/              # Core utilities and theme
├── features/          # Feature-first architecture
│   ├── models/        # Data models
│   ├── providers/     # State management
│   ├── character_chat/     # Chat with digital twins
│   ├── character_gallery/  # View all characters
│   ├── character_interview/ # Create new characters
│   └── landing_page/       # Main entry point
├── main.dart          # App entry point
```

## Configuration

The app uses several environment variables which should be stored in a `.env` file:

```
OPENROUTER_API_KEY=your_api_key_here
```

You can obtain an API key from [OpenRouter](https://openrouter.ai/).

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Powered by OpenRouter API
- Built with Flutter and Provider for state management
- Dark theme inspiration from various sci-fi interfaces
