import 'dart:io';
import 'text_cleaner.dart';

void main() {
  stdout.write('Enter text to clean (type "exit" to quit):\n');

  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();

    if (input == null || input.toLowerCase() == 'exit') {
      break;
    }

    final cleaned = TextCleaner.cleanText(input);
    stdout.write('Cleaned text:\n$cleaned\n\n');
  }

  stdout.write('Goodbye!\n');
}
