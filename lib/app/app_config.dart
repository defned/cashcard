import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

class AppConfig {
  static File _configFile;
  static Map<String, dynamic> _config;
  AppConfig._();

  static init() {
    if (Platform.isWindows) {
      _configFile = File(
          join(File(Platform.resolvedExecutable).parent.path, "config.json"));
    } else if (Platform.isMacOS) {
      _configFile =
          File(join(Directory("~").absolute.parent.path, "config.json"));
    } else
      throw "Not supported platform";

    if (!_configFile.existsSync()) {
      try {
        print("Configuration is not found");
        print("Create configuration on filesystem at '${_configFile.path}'");
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
        print("ERROR - ${e.toString()}");
        throw e;
      }
    }

    print("Load configuration from filesystem from '${_configFile.path}'");
    _config = jsonDecode(_configFile.readAsStringSync());
  }

  static store() {
    print("Store configuration on filesystem ...");
    try {
      _configFile.writeAsStringSync(jsonEncode(_config));
      print("Done");
    } catch (e) {
      print("ERROR - ${e.toString()}");
      throw e;
    }
  }

  static get dbName => _config["db"]["dbName"];
  static set dbName(String name) => _config["db"]["dbName"] = name;

  static get dbHost => _config["db"]["host"];
  static set dbHost(String host) => _config["db"]["host"] = host;

  static get dbPort => _config["db"]["port"];
  static set dbPort(int port) => _config["db"]["port"] = port;

  static get dbUserName => _config["db"]["userName"];
  static set dbUserName(String userName) =>
      _config["db"]["userName"] = userName;

  static get dbPassword => _config["db"]["password"];
  static set dbPassword(String password) =>
      _config["db"]["password"] = password;

  static get comPort => _config["com"]["port"];
  static set comPort(String port) => _config["com"]["port"] = port;

  static get comBaudrate => _config["com"]["baudrate"];
  static set comBaudrate(int baudrate) => _config["com"]["baudrate"] = baudrate;

  static get comStopbits => _config["com"]["stopbits"];
  static set comStopbits(int stopbits) => _config["com"]["stopbits"] = stopbits;

  static get comDatabits => _config["com"]["databits"];
  static set comDatabits(int databits) => _config["com"]["databits"] = databits;

  static get comParity => _config["com"]["parity"];
  static set comParity(int parity) => _config["com"]["parity"] = parity;

  static get comDelay => _config["com"]["delay"];
  static set comDelay(int delay) => _config["com"]["delay"] = delay;

  static get language => _config["language"];
  static set language(String language) => _config["language"] = language;
}
