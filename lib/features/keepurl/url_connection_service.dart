import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class UrlConnectionConfig {
  final int port;
  final String token;

  const UrlConnectionConfig({
    required this.port,
    required this.token,
  });

  Map<String, dynamic> toJson() => {'port': port, 'token': token};

  factory UrlConnectionConfig.fromJson(Map<String, dynamic> json) {
    return UrlConnectionConfig(
      port: json['port'] as int? ?? defaultPort,
      token: json['token'] as String,
    );
  }

  static const defaultPort = 17823;
}

class UrlConnectionService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'connection.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$_fileName');
  }

  Future<UrlConnectionConfig> loadOrCreate() async {
    final file = await _file;
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      if (jsonString.trim().isNotEmpty) {
        final decoded = json.decode(jsonString) as Map<String, dynamic>;
        return UrlConnectionConfig.fromJson(decoded);
      }
    }

    final config = UrlConnectionConfig(
      port: UrlConnectionConfig.defaultPort,
      token: const Uuid().v4(),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config.toJson()),
    );
    return config;
  }
}
