import 'dart:io';

import 'package:example_flutter/app/app_config.dart';

log(Object msg) {
  final message = "[${DateTime.now()}] $msg\r\n";
  print(message);
  if (AppConfig.logFile != null) {
    AppConfig.logFile.writeAsStringSync(message, mode: FileMode.append);
  }
}
