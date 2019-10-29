// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:io';
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

  Isolate myIsolateInstance =
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

  // SerialPort sp;
  // try {
  //   //SerialPort.getAvailablePorts()[0]
  //   sp = SerialPort(params[1])
  //     ..onData = (onData) {
  //       params[0].send(onData);
  //     }
  //     ..open();
  // } finally {
  //   // sp.close();
  // }
}

Isolate _isolate;

void main() async {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  AppConfig.init();

  SendPort mainToIsolateStream = await initIsolate();
  print("Init");
  mainToIsolateStream.send([IsolateState.INIT, AppConfig.port]);
  sleep(Duration(seconds: 10));
  print("Exit");
  mainToIsolateStream.send([IsolateState.EXIT]);
  sleep(Duration(seconds: 1));
  print("Init");
  mainToIsolateStream.send([IsolateState.INIT, AppConfig.port]);

  // final ReceivePort _toIsolate = ReceivePort();

  // _isolate =
  //     await Isolate.spawn(createIsolate, _toIsolate.sendPort);
  // _toIsolate.listen((data) {
  //   print(data);
  //   serialPort.sink.add(String.fromCharCodes(data));
  // });

  // runApp(AppComponent());
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
