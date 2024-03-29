import 'dart:async';
import 'dart:isolate';

import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/app/app_config.dart';
import 'package:example_flutter/util/logging.dart';
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
      log('[isolateToMainStream] data:${data.toString().trim()}, raw:${data.toString().codeUnits}');
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

  SerialPort _serialPort;
  mainToIsolateStream.listen((data) {
    //NOTE: Different isolate, log is not avaliable
    print(
        '[mainToIsolateStream] ${data.toString().trim()} ${data.toString().codeUnits}');
    if (data[0] == IsolateState.INIT) {
      print("Initialize and open serialport");
      _serialPort = SerialPort(
        data[1],
        baudrate: data[2],
        databits: data[3],
        parity: data[4],
        stopbits: data[5],
        delay: data[6],
      )
        ..onData = (onData) {
          isolateToMainStream.send(String.fromCharCodes(onData));
        }
        ..open();
    } else if (data[0] == IsolateState.EXIT) {
      log("Closing serialport");
      _serialPort.close();
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
  serialPortMainToIsolateStream.send([
    IsolateState.INIT,
    AppConfig.comPort,
    AppConfig.comBaudrate,
    AppConfig.comDatabits,
    AppConfig.comParity,
    AppConfig.comStopbits,
    AppConfig.comDelay,
  ]);

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
//   }, zoneSpecification: ZoneSpecification(log: handlePrint));
// }
