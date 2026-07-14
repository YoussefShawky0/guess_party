import 'dart:convert';
import 'dart:io';

import 'package:guess_party/core/config/app_config.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/validate_dart_defines.dart <file>');
    exitCode = 64;
    return;
  }

  final file = File(args.single);
  if (!file.existsSync()) {
    stderr.writeln('Define file was not found.');
    exitCode = 66;
    return;
  }

  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw const FormatException('Define file must be a JSON object.');
    }
    final values = decoded.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    AppConfig.fromMap(values);
    stdout.writeln('Define file is valid.');
  } on AppConfigException catch (error) {
    stderr.writeln('Invalid define file: ${error.message}');
    exitCode = 78;
  } on FormatException catch (error) {
    stderr.writeln('Invalid define file format: ${error.message}');
    exitCode = 65;
  }
}
