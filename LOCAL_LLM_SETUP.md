# Local LLM Setup Guide

This guide explains how to set up and use the local LLM feature in the Afterlife app, which allows you to run AI models directly on your device for enhanced privacy and offline usage.

## Overview

The local LLM feature integrates with the `flutter_gemma` library to run Gemma models locally on your device. This provides:

- **Privacy**: Your conversations stay on your device
- **Offline Usage**: Chat with characters without an internet connection
- **Cost Savings**: No API costs for local model usage
- **Hybrid Approach**: Automatically fallback to cloud AI when needed

## Prerequisites

1. **Flutter SDK**: 3.19 or higher
2. **Dart SDK**: 3.7 or higher
3. **Device Requirements**:
   - Android: API level 21+ (Android 5.0+)
   - iOS: iOS 12.0+
   - Minimum 4GB RAM (8GB recommended)
   - At least 2GB free storage space

## Installation

### 1. Install Dependencies

The required dependencies are already included in `pubspec.yaml`:

```yaml
dependencies:
  flutter_gemma: ^0.2.2
  file_picker: ^8.0.6
```

Run the following command to install:

```bash
flutter pub get
```

### 2. Download a Compatible Model

You need to download a compatible Gemma model file. The recommended model is:

- **gemma-3n-E2B-it-litert-preview** (Recommended)
- Other compatible Gemma models in `.bin`, `.gguf`, or `.tflite` format

#### Option A: Manual Download

1. Visit the official Gemma model repository
2. Download the model file to your device
3. Note the file path for configuration

#### Option B: Using the App (Future Feature)

The app includes a placeholder for automatic model downloading, which will be implemented in future versions.

## Configuration

### 1. Access Local AI Settings

1. Open the Afterlife app
2. Go to **Settings** → **Local AI Settings**
3. Configure the following options:

### 2. Enable Local AI

1. Toggle **Enable Local AI** to ON
2. The app will attempt to initialize the local model

### 3. Set Model Path

1. Tap **Model File** → **Folder Icon**
2. Select your downloaded model file
3. The app will validate and load the model

### 4. Configure Performance Settings

- **Max Tokens**: Set the maximum response length (256-4096 tokens)
- **Temperature**: Adjust creativity level (0.1-1.0)
  - Lower values = more focused responses
  - Higher values = more creative responses

### 5. Choose AI Provider

Select your preferred AI provider:

- **Local AI**: Always use local model
- **Cloud AI (OpenRouter)**: Always use cloud API
- **Auto (Smart Selection)**: Automatically choose the best option

## Usage

### Automatic Hybrid Mode

When **Auto** is selected, the app will:

1. **Prefer Local AI** if the model is loaded and available
2. **Fallback to Cloud AI** if local AI is unavailable or encounters errors
3. **Provide seamless experience** without user intervention

### Manual Provider Selection

You can manually choose which AI provider to use:

- **Local AI**: For privacy-focused, offline conversations
- **Cloud AI**: For advanced capabilities and faster responses

### Character Interactions

The local LLM works with all app features:

- ✅ Character interviews and creation
- ✅ Famous character chats
- ✅ Custom character conversations
- ✅ Multi-language support

## Troubleshooting

### Common Issues

#### 1. Model Not Loading

**Error**: "Model file not found" or "Failed to load model"

**Solutions**:
- Verify the model file path is correct
- Ensure the model file is in a supported format (.bin, .gguf, .tflite)
- Check that you have sufficient storage space
- Try restarting the app

#### 2. Performance Issues

**Error**: Slow responses or app crashes

**Solutions**:
- Reduce max tokens setting
- Lower temperature setting
- Ensure your device meets minimum requirements
- Close other apps to free up memory

#### 3. Initialization Errors

**Error**: "Failed to initialize local LLM"

**Solutions**:
- Check device compatibility
- Verify model file integrity
- Restart the app
- Clear app data if necessary

### Debug Information

The app provides detailed debug information:

1. Go to **Settings** → **Local AI Settings**
2. Check the **Status** section for:
   - Model loading status
   - Error messages
   - Configuration details

## Performance Optimization

### Device Optimization

1. **Close Background Apps**: Free up RAM for model processing
2. **Sufficient Storage**: Ensure at least 2GB free space
3. **Power Management**: Connect to charger for extended sessions

### Model Optimization

1. **Choose Appropriate Model Size**: Smaller models = faster responses
2. **Adjust Max Tokens**: Lower values = faster generation
3. **Optimize Temperature**: Find the right balance for your use case

## Privacy and Security

### Data Privacy

- **Local Processing**: Conversations are processed entirely on your device
- **No Data Transmission**: Local AI doesn't send data to external servers
- **Secure Storage**: Settings and model data are stored securely

### Hybrid Mode Privacy

When using **Auto** mode:
- Local AI is preferred when available
- Cloud AI is used as fallback only when necessary
- You can monitor which provider is being used in debug logs

## Advanced Configuration

### Developer Options

For advanced users, you can:

1. **Monitor Provider Usage**: Check debug logs to see which AI provider is being used
2. **Custom Model Paths**: Manually specify model file locations
3. **Performance Tuning**: Adjust settings based on your device capabilities

### Integration with Existing Features

The local LLM seamlessly integrates with:

- **Character Creation**: Interview process works with local AI
- **Famous Characters**: All historical figures support local AI
- **Multi-language**: Local AI respects language preferences
- **Chat History**: Conversations are stored regardless of AI provider

## Future Enhancements

Planned features include:

- **Automatic Model Download**: Built-in model downloading
- **Model Management**: Easy switching between different models
- **Performance Monitoring**: Real-time performance metrics
- **Advanced Settings**: More granular control options

## Support

If you encounter issues:

1. **Check Debug Information**: Settings → Local AI Settings → Status
2. **Review Error Messages**: Look for specific error details
3. **Restart the App**: Often resolves temporary issues
4. **Clear App Data**: Last resort for persistent problems

## Technical Details

### Architecture

The local LLM feature uses a hybrid architecture:

```
User Input → HybridChatService → LocalLLMService / OpenRouter API
                                      ↓
                                 Flutter Gemma
                                      ↓
                                 Local Model
```

### File Structure

```
lib/
├── core/
│   └── services/
│       ├── local_llm_service.dart      # Local LLM integration
│       └── hybrid_chat_service.dart     # Hybrid provider logic
└── features/
    └── settings/
        └── local_llm_settings_screen.dart  # UI for configuration
```

### Dependencies

- `flutter_gemma`: Core local LLM functionality
- `file_picker`: Model file selection
- `shared_preferences`: Settings persistence
- `path_provider`: File system access

---

This completes the local LLM setup guide. The feature provides a powerful, privacy-focused alternative to cloud-based AI while maintaining seamless integration with the existing Afterlife app experience. 