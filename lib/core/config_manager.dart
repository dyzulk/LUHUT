import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  bool enablePrettyUrls;
  int nginxPort;
  int mysqlPort;
  int phpPort;
  bool autoStart;

  AppConfig({
    this.enablePrettyUrls = true,
    this.nginxPort = 80,
    this.mysqlPort = 3306,
    this.phpPort = 9000,
    this.autoStart = false,
  });

  Map<String, dynamic> toJson() => {
    'enablePrettyUrls': enablePrettyUrls,
    'nginxPort': nginxPort,
    'mysqlPort': mysqlPort,
    'phpPort': phpPort,
    'autoStart': autoStart,
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      enablePrettyUrls: json['enablePrettyUrls'] ?? true,
      nginxPort: json['nginxPort'] ?? 80,
      mysqlPort: json['mysqlPort'] ?? 3306,
      phpPort: json['phpPort'] ?? 9000,
      autoStart: json['autoStart'] ?? false,
    );
  }
}

class ConfigManager extends ChangeNotifier {
  AppConfig _config = AppConfig();
  final String _configPath = 'bin/system/config.json';
  final String _nginxConfPath = 'bin/nginx/conf/nginx.conf';

  AppConfig get config => _config;

  ConfigManager() {
    _loadConfig();
    _initAutoStart();
  }

  Future<void> _initAutoStart() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  Future<void> _loadConfig() async {
    try {
      final file = File(_configPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        _config = AppConfig.fromJson(jsonDecode(content));
        notifyListeners();
      } else {
        await saveConfig(_config);
      }
    } catch (e) {
      print("Error loading config: $e");
    }
  }

  Future<void> saveConfig(AppConfig newConfig) async {
    // Check if autoStart changed
    if (_config.autoStart != newConfig.autoStart) {
      if (newConfig.autoStart) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    }

    _config = newConfig;
    notifyListeners();

    try {
      // 1. Save to JSON
      final file = File(_configPath);
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(_config.toJson()));

      // 2. Update Nginx Config if Ports changed
      await _updateNginxConfig();

    } catch (e) {
      print("Error saving config: $e");
    }
  }

  Future<void> _updateNginxConfig() async {
    final file = File(_nginxConfPath);
    if (!await file.exists()) return;

    String content = await file.readAsString();

    final portRegex = RegExp(r'listen\s+(\d+);');
    content = content.replaceAllMapped(portRegex, (match) {
        return 'listen       ${_config.nginxPort};';
    });

    final phpRegex = RegExp(r'fastcgi_pass\s+127.0.0.1:(\d+);');
    content = content.replaceAllMapped(phpRegex, (match) {
        return 'fastcgi_pass   127.0.0.1:${_config.phpPort};';
    });
    
    await file.writeAsString(content);
  }
}
