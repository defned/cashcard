import 'dart:async';

import 'package:example_flutter/db/db.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/widget/subpage.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  StreamSubscription<String> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = serialPort.stream.listen((onData) {
      _cardNumberFieldController.text = onData;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  final FocusNode cardIdFocus = FocusNode();
  @override
  Widget build(BuildContext context) {
    return SubPage(
      onPop: () {},
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
                    children: <Widget>[
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
                      onPressed: () async {
                        // await get(_cardNumberFieldController.value.text, _cardOwnerFieldKey.currentState.value.toString());
                      },
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
