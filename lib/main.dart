import 'dart:async';
import 'dart:isolate';

import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/app/app_config.dart';
import 'package:ffi_libserialport/libserialport.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';

final StreamController<String> serialPort =
    StreamController<String>.broadcast();

enum IsolateState { INIT, EXIT }

Future<SendPort> initIsolate() async {
  Completer completer = new Completer<SendPort>();
  ReceivePort isolateToMainStream = ReceivePort();

  isolateToMainStream.listen((data) {
    if (data is SendPort) {
      SendPort mainToIsolateStream = data;
      completer.complete(mainToIsolateStream);
    } else {
      print('[isolateToMainStream] $data');
      serialPort.sink.add(data);
    }
  });

  serialPortIsolate =
      await Isolate.spawn(createIsolate, isolateToMainStream.sendPort);
  return completer.future;
}

/// Creates an isolate for the serial port reading
void createIsolate(SendPort isolateToMainStream) {
  ReceivePort mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);

  SerialPort serialPort;
  mainToIsolateStream.listen((data) {
    print('[mainToIsolateStream] $data');
    if (data[0] == IsolateState.INIT) {
      print("Initialize and open serialport");
      serialPort = SerialPort(data[1])
        ..onData = (onData) {
          isolateToMainStream.send(String.fromCharCodes(onData));
        }
        ..open();
    } else if (data[0] == IsolateState.EXIT) {
      print("Closing serialport");
      serialPort.close();
    }
  });
}

Isolate serialPortIsolate;
SendPort serialPortMainToIsolateStream;

void main() async {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  app = Application();

  serialPortMainToIsolateStream = await initIsolate();
  serialPortMainToIsolateStream.send([IsolateState.INIT, AppConfig.port]);

  runApp(AppComponent());
}

// void main() {
//   // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
//   debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

//   WidgetsFlutterBinding.ensureInitialized();
//   runZoned(() {
//     initLogging();
//     // BlocSupervisor.delegate = EflyrBlocDelegate();

//     CatcherOptions debugOptions = CatcherOptions(
//       // FullPageReportMode(),
//       SilentReportMode(),
//       [ConsoleHandler(), SendEventHandler()]);

//   disableLogging();

//   Catcher(AppComponent(),
//       debugConfig: debugOptions, releaseConfig: debugOptions);

//   initLogging();
//   }, zoneSpecification: ZoneSpecification(print: handlePrint));
// }
