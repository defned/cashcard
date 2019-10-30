import 'dart:async';

import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/db/db.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/widget/subpage.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Regsitration page
class TopUpPage extends StatefulWidget {
  /// Const constructor
  const TopUpPage({Key key}) : super(key: key);

  @override
  _TopUpPageState createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage>
    with StateWithLocalization<TopUpPage> {
  final TextEditingController _cardNumberFieldController =
      TextEditingController();
  final GlobalKey<FormFieldState> _cardNumberFieldKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _propertyFieldKey =
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
      title: tr('topupPageTitle'),
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
                      Text(tr('amount'), style: TextStyle(fontSize: 40)),
                      TextFormField(
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold),
                        key: _propertyFieldKey,
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
                        await app.db.topUp(
                            _cardNumberFieldController.value.text,
                            int.parse(_propertyFieldKey.currentState.value));
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            tr('topupPageAction'),
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