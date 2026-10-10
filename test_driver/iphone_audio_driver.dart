import 'dart:convert';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      if (data != null) {
        // Only sanitized assertions/stages, never URLs or credentials.
        // ignore: avoid_print
        print(jsonEncode(data));
      }
    });
