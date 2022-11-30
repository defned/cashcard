import 'package:cashcard/app/app.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:cashcard/util/serialport.dart';

// final StreamController<String> serialPort =
//     StreamController<String>.broadcast();

// enum IsolateState { INIT, EXIT }

// Future<SendPort> initIsolate() async {
//   Completer<SendPort> completer = Completer();
//   ReceivePort isolateToMainStream = ReceivePort();

//   isolateToMainStream.listen((data) {
//     if (data is SendPort) {
//       SendPort mainToIsolateStream = data;
//       completer.complete(mainToIsolateStream);
//     } else {
//       log('[isolateToMainStream] $data');
//       serialPort.sink.add(data);
//     }
//   });

//   serialPortIsolate =
//       await Isolate.spawn(createIsolate, isolateToMainStream.sendPort);
//   return completer.future;
// }

// /// Creates an isolate for the serial port reading
// void createIsolate(SendPort isolateToMainStream) {
//   ReceivePort mainToIsolateStream = ReceivePort();
//   isolateToMainStream.send(mainToIsolateStream.sendPort);

//   SerialPort serialPort;
//   mainToIsolateStream.listen((data) {
//     log('[mainToIsolateStream] $data');
//     if (data[0] == IsolateState.INIT) {
//       log("Initialize and open serialport");
//       serialPort = SerialPort(
//         data[1],
//         baudrate: data[2],
//         databits: data[3],
//         parity: data[4],
//         stopbits: data[5],
//         delay: data[6],
//       )
//         ..onData = (onData) {
//           isolateToMainStream.send(String.fromCharCodes(onData));
//         }
//         ..open();
//     } else if (data[0] == IsolateState.EXIT) {
//       log("Closing serialport");
//       serialPort.close();
//     }
//   });
// }

// late Isolate serialPortIsolate;
// late SendPort serialPortMainToIsolateStream;

void main() async {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  app = Application();

  // serialPortMainToIsolateStream = await initIsolate();
  // serialPortMainToIsolateStream.send([
  //   IsolateState.INIT,
  //   AppConfig.comPort,
  //   AppConfig.comBaudrate,
  //   AppConfig.comDatabits,
  //   AppConfig.comParity,
  //   AppConfig.comStopbits,
  //   AppConfig.comDelay,
  // ]);

  final name = SerialPort.availablePorts.first;
  // final name = AppConfig.comPort;
  final port = SerialPort(name);

//   if (!port.openRead()) {
//     log(SerialPort.lastError);
//     return;
//   }
//
  serialPort = MySerialPortReader(port, timeout: 1000);
  // reader.stream.listen((data) {
  //   log('Received: ${utf8.decode(data)}');
  // }, onDone: () {
  //   log('Done');
  // });

  runApp(const AppComponent());
}

late MySerialPortReader serialPort;
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
