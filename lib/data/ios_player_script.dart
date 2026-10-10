import 'package:flutter/services.dart';
// The provider exposes its solver contract from these paths in 3.1.0.
// Keep the package pinned and cover this adapter with an iOS integration test.
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/challenges/ejs/base_ejs_solver.dart';
// ignore: implementation_imports
import 'package:youtube_explode_dart/src/reverse_engineering/challenges/ejs/ejs.dart';

/// Runs the public player script in the phone's isolated JavaScriptCore VM.
/// No host functions, network bridge, credentials or external process are exposed.
class IosPlayerScript extends BaseEJSSolver {
  static const _channel = MethodChannel('aleksound/native_music');
  Future<void>? _initialization;
  Future<void> _initialize() async {
    final modules =
        await EJSBuilder.getJSModules().timeout(const Duration(seconds: 20));
    await _channel.invokeMethod<void>('initializePlayerScript', modules);
  }

  @override
  Future<String> executeJavaScript(String jsCode) async {
    try {
      await (_initialization ??= _initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
    final result = await _channel
        .invokeMethod<String>('evaluatePlayerScript', jsCode)
        .timeout(const Duration(seconds: 15));
    if (result == null) {
      throw const FormatException(
          'No se pudo procesar el audio de esta versión.');
    }
    return result;
  }
}
