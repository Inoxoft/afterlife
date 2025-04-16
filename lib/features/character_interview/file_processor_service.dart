import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:afterlife/features/character_interview/chat_service.dart';
import 'prompts.dart';

class FileProcessorService {
  static Future<String> processFile(File file) async {
    final extension = path.extension(file.path).toLowerCase();

    try {
      switch (extension) {
        case '.txt':
          return await _processTextFile(file);
        case '.pdf':
          return await _processPdfFile(file);
        case '.doc':
        case '.docx':
          return await _processWordFile(file);
        case '.eml':
          return await _processEmailFile(file);
        default:
          throw Exception('Unsupported file type: $extension');
      }
    } catch (e) {
      throw Exception('Error processing file: $e');
    }
  }

  static Future<String> _processTextFile(File file) async {
    return await file.readAsString();
  }

  static Future<String> _processPdfFile(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  static Future<String> _processWordFile(File file) async {
    // For now, we'll just read as text
    // TODO: Implement proper Word document parsing
    return await file.readAsString();
  }

  static Future<String> _processEmailFile(File file) async {
    final content = await file.readAsString();
    // Extract email body, removing headers
    final lines = content.split('\n');
    final bodyStart = lines.indexWhere((line) => line.trim().isEmpty) + 1;
    return lines.sublist(bodyStart).join('\n');
  }

  static Future<String> generateCharacterCard(String content) async {
    try {
      final response = await ChatService.sendMessage(
        messages: [
          {
            "role": "user",
            "content": "Create a character card from this content:\n\n$content",
          },
        ],
        systemPrompt: InterviewPrompts.fileProcessingSystemPrompt,
      );

      return response;
    } catch (e) {
      throw Exception('Error generating character card: $e');
    }
  }

  static Future<File?> pickFile() async {
    final typeGroup = XTypeGroup(
      label: 'Documents',
      extensions: ['txt', 'pdf', 'doc', 'docx', 'eml'],
    );

    final XFile? result = await openFile(acceptedTypeGroups: [typeGroup]);

    if (result != null) {
      return File(result.path);
    }
    return null;
  }
}
