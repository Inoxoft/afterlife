import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

/// Service for detecting leading questions using the trained ONNX model
class LeadingQuestionDetector {
  static OrtSession? _session;
  static Map<String, dynamic>? _vocab;
  static Map<String, dynamic>? _scaler;
  static bool _isInitialized = false;

  /// Initialize the detector by loading the ONNX model and preprocessing files
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the ONNX model
      final modelBytes = await rootBundle.load('assets/models/model.onnx');
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelBytes.buffer.asUint8List(), sessionOptions);

      // Load vocabulary
      final vocabString = await rootBundle.loadString('assets/models/vocab.json');
      _vocab = json.decode(vocabString);

      // Load scaler parameters
      final scalerString = await rootBundle.loadString('assets/models/scaler.json');
      _scaler = json.decode(scalerString);

      _isInitialized = true;
      print('LeadingQuestionDetector initialized successfully');
      print('📋 Model input names: ${_session!.inputNames}');
      print('📋 Model output names: ${_session!.outputNames}');
    } catch (e) {
      print('Error initializing LeadingQuestionDetector: $e');
      throw Exception('Failed to initialize leading question detector: $e');
    }
  }

  /// Detect if a message contains leading questions
  /// Returns a Map with 'isLeading' (bool) and 'confidence' (double 0.0-1.0)
  static Future<Map<String, dynamic>> detectLeadingQuestion(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_session == null || _vocab == null || _scaler == null) {
      throw Exception('Detector not properly initialized');
    }

    try {
      print('🔍 Analyzing message: "$message"');
      
      // Preprocess the message to create feature vector
      final features = _preprocessMessage(message);
      
      // Debug: Count non-zero features
      final nonZeroFeatures = features.where((f) => f != 0.0).length;
      final maxFeature = features.reduce((a, b) => a.abs() > b.abs() ? a : b);
      print('📊 Features: ${features.length} total, $nonZeroFeatures non-zero, max: $maxFeature');
      
      // Convert to Float32List for ONNX model compatibility
      final float32Features = Float32List.fromList(features);
      
      // Create input tensor - use the first input name from the session
      final inputName = _session!.inputNames.first;
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        float32Features,
        [1, features.length],
      );

      // Run inference
      final inputs = {inputName: inputTensor};
      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);
      
      // Get prediction (assuming binary classification with sigmoid output)  
      final outputTensor = outputs.first;
      double confidence = 0.0;
      
      try {
        final prediction = outputTensor?.value;
        print('🔬 Raw prediction: $prediction (${prediction.runtimeType})');
        
        if (prediction is List<List<double>>) {
          // 2D tensor [1, 1] or [1, num_classes]
          confidence = prediction.first.first.toDouble();
        } else if (prediction is List<double>) {
          // 1D tensor [1] or [num_classes]
          confidence = prediction.first.toDouble();
        } else if (prediction is List<num>) {
          // Generic numeric list
          confidence = prediction.first.toDouble();
        } else {
          print('❌ Unexpected prediction format: ${prediction.runtimeType}');
          confidence = 0.0;
        }
        
        print('📈 Confidence: $confidence');
      } catch (e) {
        print('❌ Error extracting prediction: $e');
        confidence = 0.0;
      }
      
      // Clean up
      inputTensor.release();
      for (final output in outputs) {
        output?.release();
      }
      runOptions.release();

      final isLeading = confidence > 0.3; // Temporarily lowered from 0.5 for testing
      print('🎯 Result: ${isLeading ? "LEADING" : "NOT LEADING"} (confidence: $confidence)');

      return {
        'isLeading': isLeading,
        'confidence': confidence,
        'message': _getWarningMessage(confidence),
      };
    } catch (e) {
      print('❌ Error during inference: $e');
      return {
        'isLeading': false,
        'confidence': 0.0,
        'message': 'Error analyzing message',
      };
    }
  }

  /// Preprocess the message using TF-IDF vectorization
  static List<double> _preprocessMessage(String message) {
    final vocab = _vocab!['vocab'] as Map<String, dynamic>;
    final mean = (_scaler!['mean'] as List).cast<double>();
    final scale = (_scaler!['scale'] as List).cast<double>();
    
    // Clean and expand contractions
    String cleanMessage = message.toLowerCase().trim();
    print('📝 Original: "$message" -> Cleaned: "$cleanMessage"');
    
    // Expand common contractions to match training data preprocessing
    final contractions = {
      "don't": "do not",
      "won't": "will not", 
      "can't": "cannot",
      "shouldn't": "should not",
      "wouldn't": "would not",
      "couldn't": "could not",
      "isn't": "is not",
      "aren't": "are not",
      "wasn't": "was not",
      "weren't": "were not",
      "haven't": "have not",
      "hasn't": "has not",
      "hadn't": "had not",
      "doesn't": "does not",
      "didn't": "did not",
      "you're": "you are",
      "they're": "they are",
      "we're": "we are",
      "i'm": "i am",
      "he's": "he is",
      "she's": "she is",
      "it's": "it is",
      "that's": "that is",
      "what's": "what is",
      "where's": "where is",
      "how's": "how is",
      "who's": "who is",
      "there's": "there is",
      "here's": "here is",
    };
    
    // Apply contraction expansion
    for (final entry in contractions.entries) {
      if (cleanMessage.contains(entry.key)) {
        print('🔄 Expanding "${entry.key}" -> "${entry.value}"');
        cleanMessage = cleanMessage.replaceAll(entry.key, entry.value);
      }
    }
    
    // Remove punctuation and extra whitespace
    cleanMessage = cleanMessage.replaceAll(RegExp(r'[^\w\s]'), ' ');
    cleanMessage = cleanMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    final words = cleanMessage.split(' ');
    print('🔤 Final tokens: $words');
    
    // Create feature vector (TF-IDF style)
    final features = List<double>.filled(mean.length, 0.0);
    final matchedFeatures = <String>[];
    final matchedIndices = <int>{};
    
    // Process individual words and n-grams
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      // Single words
      if (vocab.containsKey(word)) {
        final index = vocab[word] as int;
        if (index < features.length) {
          features[index] += 1.0;
          matchedFeatures.add('word: "$word" (idx: $index)');
          matchedIndices.add(index);
        }
      }
      
      // Bigrams
      if (i < words.length - 1) {
        final bigram = '${words[i]} ${words[i + 1]}';
        if (vocab.containsKey(bigram)) {
          final index = vocab[bigram] as int;
          if (index < features.length) {
            features[index] += 1.0;
            matchedFeatures.add('bigram: "$bigram" (idx: $index)');
            matchedIndices.add(index);
          }
        }
      }
      
      // Trigrams
      if (i < words.length - 2) {
        final trigram = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
        if (vocab.containsKey(trigram)) {
          final index = vocab[trigram] as int;
          if (index < features.length) {
            features[index] += 1.0;
            matchedFeatures.add('trigram: "$trigram" (idx: $index)');
            matchedIndices.add(index);
          }
        }
      }
    }
    
    print('✅ Matched features: ${matchedFeatures.join(", ")}');
    print('🎯 Matched indices count: ${matchedIndices.length}');
    
    // Let's try WITH scaling again but with better debugging
    print('🧪 Testing WITH scaling - applying StandardScaler normalization');
    
    // Apply scaling (standardization) ONLY to matched features
    // Keep unmatched features as 0.0 (don't subtract mean from zeros)
    for (final index in matchedIndices) {
      if (scale[index] > 0) {
        final originalValue = features[index];
        final meanValue = mean[index];
        final scaleValue = scale[index];
        features[index] = (features[index] - mean[index]) / scale[index];
        
        // Debug the first few scalings
        if (matchedIndices.length <= 10) {
          print('🔢 Scaling idx $index: $originalValue -> ($originalValue - $meanValue) / $scaleValue = ${features[index]}');
        }
      }
    }
    
    return features;
  }

  /// Get appropriate warning message based on confidence
  static String _getWarningMessage(double confidence) {
    if (confidence > 0.6) {
      return 'This appears to be a leading question that might influence the AI\'s response. Consider rephrasing for a more authentic conversation.';
    } else if (confidence > 0.45) {
      return 'This question might contain assumptions. The AI will respond based on its character, not implied memories.';
    } else if (confidence > 0.3) {
      return 'Consider asking open-ended questions for more genuine responses.';
    } else {
      return '';
    }
  }

  /// Dispose of resources
  static void dispose() {
    _session?.release();
    _session = null;
    _vocab = null;
    _scaler = null;
    _isInitialized = false;
  }
} 