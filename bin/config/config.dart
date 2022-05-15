import 'dart:io';

import 'package:settings_yaml/settings_yaml.dart';

class Config {
  static String _nodeUrlWs = 'ws://127.0.0.1:35998';

  static String _databaseAddress = '127.0.0.1';
  static int _databasePort = 5432;
  static String _databaseName = '';
  static String _databaseUsername = '';
  static String _databasePassword = '';

  static String get nodeUrlWs {
    return _nodeUrlWs;
  }

  static String get databaseAddress {
    return _databaseAddress;
  }

  static int get databasePort {
    return _databasePort;
  }

  static String get databaseName {
    return _databaseName;
  }

  static String get databaseUsername {
    return _databaseUsername;
  }

  static String get databasePassword {
    return _databasePassword;
  }

  static void load() {
    final settings = SettingsYaml.load(
        pathToSettings: '${Directory.current.path}/config.yaml');

    _nodeUrlWs = settings['node_url_ws'] as String;

    _databaseAddress = settings['database_address'] as String;
    _databasePort = settings['database_port'] as int;
    _databaseName = settings['database_name'] as String;
    _databaseUsername = settings['database_username'] as String;
    _databasePassword = settings['database_password'] as String;
  }
}
