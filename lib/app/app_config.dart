import 'dart:convert';
import 'dart:io';

import 'package:cashcard/util/logging.dart';
import 'package:path/path.dart';

class AppConfig {
  static File logFile;
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
            "stopbits": 1,
            "databits": 8,
            "parity": 0,
            "delay": 100,
          },
          "printer": {
            "name": "EPSON TM-T20III Receipt",
            "codeTable": "ISO8859-2",
            "logOnly": false,
          },
          "logging": {"filePath": "", "level": "info", "sizeLimit": 25},
          "language": "hu",
          "transformation": {"from": "^\\d{4}(.*)", "to": "\$1"}
        }));
      } catch (e) {
        log("ERROR - ${e.toString()}");
        throw e;
      }
    }

    log("Load configuration from filesystem from '${_configFile.path}'");
    _config = jsonDecode(_configFile.readAsStringSync());

    // Set up logging
    if (loggingFilePath != null || loggingSizeLimit != null) {
      File file = loggingFilePath == null
          ? File(kLOGFILEPATH)
          : File(loggingFilePath.isEmpty ? kLOGFILEPATH : loggingFilePath);

      if (!file.existsSync()) file.createSync();
      logFile = file;

      purgeLog();
    }
  }

  static void purgeLog() {
    if (logFile != null && logFile.existsSync()) {
      if (loggingSizeLimit != null &&
          logFile.statSync().size > loggingSizeLimit) {
        logFile.writeAsStringSync("", mode: FileMode.write);
      }
    }
  }

  static store() {
    log("Store configuration on filesystem ...");
    try {
      _configFile.writeAsStringSync(jsonEncode(_config));
      log("Done");
    } catch (e) {
      log("ERROR - ${e.toString()}");
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

  static get printerName => _config["printer"]["name"];
  static set printerName(String name) => _config["printer"]["name"] = name;

  static get printerCodeTable => _config["printer"]["codeTable"];
  static set printerCodeTable(String codeTable) =>
      _config["printer"]["codeTable"] = codeTable;

  static get printerLogOnly => _config["printer"]["logOnly"];
  static set printerLogOnly(bool logOnly) =>
      _config["printer"]["logOnly"] = logOnly;

  static get language => _config["language"];
  static set language(String language) => _config["language"] = language;

  static T _safeGet<T>(List<String> keyPath) {
    var configMap = _config;

    for (int i = 0; i < keyPath.length - 1; i++) {
      if (configMap.containsKey(keyPath[i]) && configMap[keyPath[i]] is Map) {
        configMap = configMap[keyPath[i]];
      } else
        return null;
    }

    if (configMap.containsKey(keyPath.last)) return configMap[keyPath.last];

    return null;
  }

  static const String kLOGFILEPATH = "log.txt";

  static String get loggingFilePath {
    String filePath = _safeGet(["logging", "filePath"]);
    String path =
        filePath != null && filePath.isNotEmpty ? filePath : kLOGFILEPATH;

    if (Platform.isWindows) {
      return File(join(File(Platform.resolvedExecutable).parent.path, path))
          .absolute
          .path;
    } else if (Platform.isMacOS) {
      return File(join(Directory("~").absolute.parent.path, path))
          .absolute
          .path;
    } else
      throw "Not supported platform";
  }

  static int get loggingSizeLimit {
    final _limit = _safeGet(["logging", "sizeLimit"]) ?? 25;
    return _limit * 1024 * 1024;
  }

  static RegExp _transformationFrom;
  static RegExp get transformationFrom {
    try {
      if (_transformationFrom == null &&
          _config.containsKey("transformation") &&
          (_config["transformation"] as Map<String, dynamic>)
              .containsKey("from") &&
          _config["transformation"]["from"] != null) {
        _transformationFrom = RegExp(_config["transformation"]["from"]);
      }
    } on Exception catch (e) {
      log("Exception: $e");
    }

    return _transformationFrom;
  }

  static String _transformationTo;
  static String get transformationTo {
    try {
      if (_transformationTo == null &&
          _config.containsKey("transformation") &&
          (_config["transformation"] as Map<String, dynamic>).containsKey("to"))
        _transformationTo = _config["transformation"]["to"];
    } on Exception catch (e) {
      log("Exception: $e");
    }

    return _transformationTo;
  }
}
