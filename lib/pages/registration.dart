import 'dart:async';
import 'dart:isolate';

import 'package:example_flutter/widget/subpage.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:ffi_libserialport/libserialport.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Creates an isolate for the serial port reading
void createIsolate(SendPort port) {
  SerialPort(SerialPort.getAvailablePorts()[0])
    ..onData = (onData) {
      print('Waiting for card ...');
      print('Card arrived $onData');
      port.send(onData);
    }
    ..open();
}
/// Regsitration page
class RegistrationPage extends StatefulWidget {
  /// Const constructor
  const RegistrationPage({Key key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with StateWithLocalization<RegistrationPage> {

  final TextEditingController _cardNumberFieldController =
      TextEditingController();
  final GlobalKey<FormFieldState> _cardNumberFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _cardOwnerFieldKey =
      GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    initIsolate();
  }

  Isolate _isolate;
  final ReceivePort _replyPort = ReceivePort();
  Future initIsolate() async {
    _isolate = await Isolate.spawn(createIsolate, _replyPort.sendPort);
    _replyPort.listen((data) {
      _cardNumberFieldController.text = String.fromCharCodes(data);
    });
  }

  @override
  void reassemble() {
    if (_isolate != null) {
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }
    super.reassemble();
  }

  @override
  void dispose() {
    if (_isolate != null) {
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }
    super.dispose();
  }

  final FocusNode cardIdFocus = FocusNode();
  @override
  Widget build(BuildContext context) {
    return SubPage(
      onPop: () {
        if (_isolate != null) {
          _isolate.kill(priority: Isolate.immediate);
          _isolate = null;
        }
      },
      title: tr('registrationPageTitle'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: <Widget>[
                Form(
                  child: Column(
                    children:
                        <Widget>[
                      Text(tr('cardId'), style: TextStyle(fontSize: 40)),
                      TextFormField(
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold),
                        key: _cardNumberFieldKey,
                        controller: _cardNumberFieldController,
                      ),
                      SizedBox(height: 30),
                      Text(tr('name'), style: TextStyle(fontSize: 40)),
                      TextFormField(
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold),
                        key: _cardOwnerFieldKey,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 80,
                    child: MaterialButton(
                      color: Colors.lightBlue.shade100,
                      onPressed: () {},
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            tr('registrationPageAction'),
                            style: TextStyle(
                                fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
