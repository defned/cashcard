import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:cashcard/usb_esc_printer/ffi/usb_esc_printer_windows.dart';
import 'package:ffi/ffi.dart';

class _PrintRequest {
  final int id;
  final String printerName;
  final int length;
  final List<int> data;

  const _PrintRequest(this.id, this.printerName, this.length, this.data);
}

class _PrintResponse {
  final int id;
  final int result;

  const _PrintResponse(this.id, this.result);
}

final Map<int, Completer<int>> _printRequests = <int, Completer<int>>{};

Future<String> sendPrintRequest(List<int> data, String printerName) async {
  final SendPort helperIsolateSendPort = await initIsolate();
  final int requestId = _nextPrintRequestId++;

  final _PrintRequest request =
      _PrintRequest(requestId, printerName, data.length, data);

  final Completer<int> completer = Completer<int>();
  _printRequests[requestId] = completer;
  helperIsolateSendPort.send(request);

  final res = await completer.future;

  if (res < 0) {
    return "failed";
  } else {
    return "success";
  }
}

/// Counter to identify [_SumRequest]s and [_SumResponse]s.
int _nextPrintRequestId = 0;

/// Mapping from [_SumRequest] `id`s to the completers corresponding to the correct future of the pending request.
// final Map<int, Completer<int>> _PrintRequests = <int, Completer<int>>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> initIsolate() async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is _PrintResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<int> completer = _printRequests[data.id];
        _printRequests.remove(data.id);
        completer.complete(data.result);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn(createIsolatePrinter, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}

void createIsolatePrinter(SendPort sendPort) async {
  final ReceivePort helperReceivePort = ReceivePort()
    ..listen((dynamic data) {
      // On the helper isolate listen to requests and respond to them.
      if (data is _PrintRequest) {
        // List<int> list = data.printerName.codeUnits;
        // Uint8List bytes = Uint8List.fromList(list);
        // Uint16List name = bytes.buffer.asUint16List();

        Pointer<Utf16> name = stringToNativeUtf16(data.printerName);
        final Pointer<Uint8> dataPtr = convertListIntToPointerUint8(data.data);

        final int result = sendPrintReq(dataPtr, data.length, name);
        final _PrintResponse response = _PrintResponse(data.id, result);

        sendPort.send(response);
        // calloc.free(dataPtr);
        free(dataPtr);
        free(name);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Send the port to the main isolate on which we can receive requests.
  sendPort.send(helperReceivePort.sendPort);
}
