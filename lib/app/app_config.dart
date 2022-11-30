import 'dart:convert';
import 'dart:io';

import 'package:cashcard/util/logging.dart';
import 'package:path/path.dart';

class AppConfig {
  static late File _configFile;
  static late Map<String, dynamic> _config;
  AppConfig._();

  static init() {
    if (Platform.isWindows) {
      _configFile = File(
          join(File(Platform.resolvedExecutable).parent.path, "config.json"));
    } else if (Platform.isMacOS) {
      _configFile =
          File(join(Directory("~").absolute.parent.path, "config.json"));
    } else {
      throw "Not supported platform";
    }

    if (!_configFile.existsSync()) {
      try {
        log("Configuration is not found");
        log("Create configuration on filesystem at '${_configFile.path}'");
        _configFile.writeAsStringSync(jsonEncode({
          "db": {
            "host": "localhost",
            "userName": "root",
            "password": "admin",
            "dbName": "cashcard",
            "port": 3306,
          },
          "com": {
            "port": "COM4",
            "baudrate": 9600,
            "stopbits": 0,
            "databits": 8,
            "parity": 0,
            "delay": 100,
          },
          "language": "en"
        }));
      } catch (e) {
        log("ERROR - ${e.toString()}");
        rethrow;
      }
    }

    log("Load configuration from filesystem from '${_configFile.path}'");
    _config = jsonDecode(_configFile.readAsStringSync());
  }

  static store() {
    log("Store configuration on filesystem ...");
    try {
      _configFile.writeAsStringSync(jsonEncode(_config));
      log("Done");
    } catch (e) {
      log("ERROR - ${e.toString()}");
      rethrow;
    }
  }

  static String get dbName => _config["db"]["dbName"];
  static set dbName(String name) => _config["db"]["dbName"] = name;

  static String get dbHost => _config["db"]["host"];
  static set dbHost(String host) => _config["db"]["host"] = host;

  static int get dbPort => _config["db"]["port"];
  static set dbPort(int port) => _config["db"]["port"] = port;

  static String get dbUserName => _config["db"]["userName"];
  static set dbUserName(String userName) =>
      _config["db"]["userName"] = userName;

  static String get dbPassword => _config["db"]["password"];
  static set dbPassword(String password) =>
      _config["db"]["password"] = password;

  static String get comPort => _config["com"]["port"];
  static set comPort(String port) => _config["com"]["port"] = port;

  static int get comBaudrate => _config["com"]["baudrate"];
  static set comBaudrate(int baudrate) => _config["com"]["baudrate"] = baudrate;

  static int get comStopbits => _config["com"]["stopbits"];
  static set comStopbits(int stopbits) => _config["com"]["stopbits"] = stopbits;

  static int get comDatabits => _config["com"]["databits"];
  static set comDatabits(int databits) => _config["com"]["databits"] = databits;

  static int get comParity => _config["com"]["parity"];
  static set comParity(int parity) => _config["com"]["parity"] = parity;

  static int get comDelay => _config["com"]["delay"];
  static set comDelay(int delay) => _config["com"]["delay"] = delay;

  static String get language => _config["language"];
  static set language(String language) => _config["language"] = language;
}
