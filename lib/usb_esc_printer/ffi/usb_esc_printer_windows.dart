import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as ffiP;
import 'package:path/path.dart';

const String _libName = 'usb_esc_printer_c';

const Set<String> _supported = {'win64'};
String _getObjectFilename() {
  final architecture = sizeOf<IntPtr>() == 4 ? '32' : '64';
  String os, extension;
  if (Platform.isWindows) {
    os = 'win';
    extension = 'dll';
  } else {
    throw Exception('Unsupported platform!');
  }

  final result = os + architecture;
  if (!_supported.contains(result)) {
    throw Exception('Unsupported platform: $result!');
  }

  return '$_libName-$result.$extension';
}

String _getPath() {
  var transformUri = (String uri) {
    int pathBeg = uri.indexOf("file:///");
    if (pathBeg != null && pathBeg > 0) {
      uri = uri.substring(pathBeg);
      return Uri.parse(uri).path;
    }
    return uri;
  };

  String objectFile = "";
  List<String> searchPaths = [
    join(File(Platform.resolvedExecutable).parent.path, _getObjectFilename()),
    if (Platform.isMacOS)
      join(
          join(File(Platform.resolvedExecutable).parent.parent.path,
              "Frameworks/App.framework/Versions/A/Resources/flutter_assets/blobs/"),
          _getObjectFilename()),
    join(Directory(".").absolute.parent.path, _getObjectFilename()),
    transformUri(Platform.script
            .resolve("src/blobs/")
            .resolve(_getObjectFilename())
            .path)
        .substring(Platform.isWindows ? 1 : 0),
    transformUri(Platform.script
            .resolve("blobs/")
            .resolve(_getObjectFilename())
            .path)
        .substring(Platform.isWindows ? 1 : 0),
    transformUri(Platform.script
            .resolve("src/blobs/")
            .resolve(_getObjectFilename())
            .path)
        .substring(Platform.isWindows ? 1 : 0)
        .replaceAll("test/", "lib/"),
    transformUri(Platform.script
            .resolve("blobs/")
            .resolve(_getObjectFilename())
            .path)
        .substring(Platform.isWindows ? 1 : 0)
        .replaceAll("test/", "lib/"),
  ];

  for (int i = 0; i < searchPaths.length; i++) {
    if (File(searchPaths[i]).existsSync()) {
      objectFile = searchPaths[i];
      break;
    }
  }

  if (objectFile.isEmpty) {
    throw "libseriaport library not found at [$searchPaths]";
  }

  print("Found libserialport library at '$objectFile'");
  return objectFile;
}

DynamicLibrary _dylib = (() {
  var path = _getPath();
  if (Platform.isWindows) {
    return DynamicLibrary.open(path);
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
})();

Pointer<Uint8> convertListIntToPointerUint8(List<int> list) {
  final ptr = allocate<Uint8>(count: list.length);
  for (var i = 0; i < list.length; i++) {
    ptr[i] = list[i];
  }
  return ptr;
}

Pointer<Utf16> stringToNativeUtf16(String str) {
  final units = str.codeUnits;
  // allocate a Uint16 buffer
  final Pointer<Uint16> result = allocate<Uint16>(count: units.length + 1);

  for (var i = 0; i < units.length; i++) {
    result[i] = units[i];
  }
  result[units.length] = 0; // null terminator

  return result.cast<Utf16>();
}

////////////////////////////////////////////////////////
/// FFI Generated
///

int Function(
  ffi.Pointer<ffi.Uint8>,
  int,
  ffi.Pointer<ffiP.Utf16>,
) sendPrintReq = _dylib
    .lookup<ffi.NativeFunction<_sendPrintReqType>>('sendPrintReq')
    .asFunction();

typedef _sendPrintReqType = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8>,
  ffi.Int32,
  ffi.Pointer<ffiP.Utf16>,
);
