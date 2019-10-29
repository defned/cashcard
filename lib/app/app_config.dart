import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

class AppConfig {
  static File _configFile;
  static Map<String, dynamic> _config;
  AppConfig._();

  static init() {
    _configFile = File(
        join(File(Platform.resolvedExecutable).parent.path, "config.json"));
    if (!_configFile.existsSync()) {
      try {
        print("Load configuration from filesystem ...");
        _configFile.writeAsStringSync(jsonEncode({
          "db": {
            "userName": "root",
            "password": "admin",
            "dbName": "cashcard",
            "port": 3306,
          },
          "port": "COM4",
          "language": "en"
        }));
      } catch (e) {
        print("ERROR - ${e.toString()}");
        throw e;
      }
    }

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
  static set dbName(String dbName) => _config["db"]["dbName"] = dbName;

  static get dbPort => _config["db"]["port"];
  static set dbPort(int port) => _config["db"]["port"] = port;

  static get dbUserName => _config["db"]["userName"];
  static set dbUserName(String userName) =>
      _config["db"]["userName"] = userName;

  static get dbPassword => _config["db"]["password"];
  static set dbPassword(String password) =>
      _config["db"]["password"] = password;

  static get port => _config["port"];
  static set port(String port) => _config["port"] = port;

  static get language => _config["language"];
  static set language(String language) => _config["language"] = language;
}
