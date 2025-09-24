import 'package:cashcard/app/app.dart';
import 'package:cashcard/util/serialporthelper.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';

void main() async {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  app = Application();

  await initSerialPort();

  runApp(AppComponent());
}
