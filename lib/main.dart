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

// import 'dart:io';

import 'package:example_flutter/app/app.dart';
// import 'package:ffi_libserialport/libserialport.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';

void main() async {
  // print(Platform.resolvedExecutable);
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  // SerialPort sp = SerialPort(SerialPort.getAvailablePorts()[0]);
  // sp.open();
  // sp.onRead.listen((onData) {
  //   print(onData);
  // });

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
