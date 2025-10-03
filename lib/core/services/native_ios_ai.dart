import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

class NativeIOSAI {
  static const MethodChannel _channel = MethodChannel('afterlife/native_ai');

  static Future<bool> isFMAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      final bool? res = await _channel.invokeMethod<bool>('isFMAvailable');
      AppLogger.debug('FM availability check', tag: 'NativeIOSAI', context: {'available': res == true});
      return res == true;
    } catch (e) {
      AppLogger.serviceError('NativeIOSAI', 'isFMAvailable failed', e);
      return false;
    }
  }

  static Future<Map<String, dynamic>> fmStatus() async {
    if (!Platform.isIOS) return {'available': false, 'reason': 'not_ios'};
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('fmStatus');
      final map = (res ?? const {});
      AppLogger.debug('FM status', tag: 'NativeIOSAI', context: {
        'available': map['available'],
        'reason': map['reason']
      });
      return {'available': map['available'] == true, 'reason': map['reason'] ?? ''};
    } catch (e) {
      AppLogger.serviceError('NativeIOSAI', 'fmStatus failed', e);
      return {'available': false, 'reason': 'channel_error'};
    }
  }

  static Future<String> generateText(String prompt) async {
    if (!Platform.isIOS) {
      AppLogger.warning('NativeIOSAI called on non-iOS platform', tag: 'NativeIOSAI');
      throw UnsupportedError('Native iOS AI is available only on iOS');
    }
    try {
      AppLogger.debug('Invoking native generateText', tag: 'NativeIOSAI', context: {
        'prompt_len': prompt.length,
      });
      final String? res = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });
      AppLogger.debug('Native generateText returned', tag: 'NativeIOSAI', context: {
        'has_res': res != null,
        'len': res?.length,
      });
      return res ?? '';
    } catch (e) {
      AppLogger.serviceError('NativeIOSAI', 'generateText failed', e);
      rethrow;
    }
  }
}


