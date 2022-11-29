// import 'dart:async';
// import 'dart:collection';
// import 'dart:convert';
// import 'dart:math';

// import 'package:flutter/foundation.dart';
// import 'package:logging/logging.dart';
// export 'package:logging/logging.dart';

// /////////////////////////////
// /// Configuration
// /////////////////////////////

// /// Logger name if you call print("message");
// const String printLoggerName = "console";

// /// Log level if you call print("message");
// const Level printLogLevel = Level.FINEST;

// /// Minimum level for automatically record stack trace of the logging line
// const Level autoRecordStackTraceLevel = Level.SEVERE;

// /// Loggers are hierarchical, each level inherits minimum log level from its parent.
// /// Implicit levels can be created as simple as "a.b.c.d.e".
// /// You can use special log levels `Level.OFF` and `Level.ALL`.
// void configureMinimumLogLevels() {
//   Logger("").level = Level.FINE; // root level
//   Logger(printLoggerName).level = _debugMode
//       ? printLogLevel
//       : Level.OFF; // Enable print() by default in debug mode

//   Logger("blocs").level = Level.FINE;

//   Logger("util.runGql").level = Level.INFO;
//   // Logger("util.runGql.GetMyBusinesses_OperationResult").level = Level.ALL;
// }

// /// Write custom filter logic here
// bool logFilter(LogRecord rec) {
//   bool allow = true;

//   // Filter logic, e.g.:
//   // allow = allow &&
//   //     rec.loggerName == printLoggerName &&
//   //     rec.message.contains("WebView");

//   return allow;
// }

// /////////////////////////////
// /// Public interface
// /////////////////////////////

// mixin LoggerProvider {
//   Logger get publicLogger => Logger("LoggerProvider.${super.runtimeType}");
// }

// final ListQueue<String> logLines = ListQueue<String>();

// void initLogging() {
//   assert(_debugMode = true);

//   hierarchicalLoggingEnabled = true;
//   recordStackTraceAtLevel = autoRecordStackTraceLevel;

//   Logger.root.clearListeners();
//   Logger.root.onRecord.listen(_handleLogRecord);

//   configureMinimumLogLevels();
//   _loggingInitialized = true;
// }

// void disableLogging() => _loggingInitialized = false;

// void handlePrint(Zone self, ZoneDelegate parent, Zone zone, String message) {
//   if (!_loggingInitialized) {
//     return parent.print(zone, message);
//   }

//   _printLogger.log(printLogLevel, message);
// }

// /////////////////////////////
// /// Private
// /////////////////////////////

// bool _debugMode = false;
// bool _loggingInitialized = false;
// Logger _printLogger = Logger(printLoggerName);

// void _handleLogRecord(LogRecord rec) {
//   if (logFilter(rec)) {
//     if (_debugMode) _logToConsole(rec);
//     _logToQueue(rec);
//   }
// }

// void _logToConsole(LogRecord rec) {
//   StringBuffer messageToPrint = StringBuffer();

//   if (rec.object == null) {
//     messageToPrint.write("${rec.message}");
//   } else {
//     messageToPrint.write("${rec.object}");
//   }

//   if (rec.error != null) {
//     messageToPrint.write(": ${rec.error}");
//   }

//   // Workaround for https://github.com/flutter/flutter/issues/22665
//   void Function(String) parentPrint = Zone.current.parent.print;
//   PrintHandler printHandler =
//       (Zone self, ZoneDelegate parent, Zone zone, String message) {
//     parentPrint(message);
//   };

//   runZoned(() {
//     String messageString = messageToPrint.toString();
//     for (String part in messageString.split("\n")) {
//       _debugPrintMultiline(
//           "${rec.time}: ${rec.level.name}: ${rec.loggerName}: $part");
//     }
//   }, zoneSpecification: ZoneSpecification(print: printHandler));
// }

// void _debugPrintMultiline(String message) {
//   if (_debugMode) {
//     const int debugPrintMaxLength =
//         800; // Less than 1000 to handle multi byte utf8 chars
//     const String headMark = "... ";
//     const String tailMark = " ...";
//     const int doubleMarkLength = headMark.length + tailMark.length;
//     const int firstLineMaxLength = debugPrintMaxLength - tailMark.length;
//     const int middleLineMaxLength = debugPrintMaxLength - doubleMarkLength;
//     const int lastLineMaxLength = debugPrintMaxLength - headMark.length;

//     if (message.length >= debugPrintMaxLength) {
//       int remainingLength = message.length;

//       debugPrint("${message.substring(0, firstLineMaxLength)}$tailMark");
//       remainingLength -= firstLineMaxLength;

//       int lineLength;
//       for (int start = firstLineMaxLength;
//           remainingLength > 0;
//           remainingLength -= lineLength, start += lineLength) {
//         bool isLastLine = remainingLength <= lastLineMaxLength;
//         lineLength = min(remainingLength,
//             isLastLine ? lastLineMaxLength : middleLineMaxLength);

//         debugPrint(
//             "$headMark${message.substring(start, start + lineLength)}${isLastLine ? "" : tailMark}");
//       }

//       return;
//     }
//   }

//   debugPrint(message);
// }

// void _logToQueue(LogRecord rec) {
//   Map<String, dynamic> logMap = {
//     "level": rec.level.toString(),
//     "loggerName": rec.loggerName,
//     "time": rec.time,
//     "stackTrace": rec.stackTrace,
//   };

//   if (rec.error != null) {
//     logMap["extra"] = rec.error;
//   }

//   if (rec.object == null) {
//     logMap["message"] = rec.message;
//   } else {
//     logMap["extra2"] = rec.object;
//   }

//   // encode to json to release references
//   String logJson = jsonEncode(logMap, toEncodable: (o) => o.toString());

//   logLines.addLast(logJson);
//   if (logLines.length > 500) {
//     logLines.removeFirst();
//   }
// }
