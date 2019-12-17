import 'dart:async';

import 'package:example_flutter/app/app.dart';
import 'package:example_flutter/main.dart';
import 'package:example_flutter/widget/subpage.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

/// Regsitration page
class RegistrationPage extends StatefulWidget {
  /// Const constructor
  const RegistrationPage({Key key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with StateWithLocalization<RegistrationPage> {
  final TextEditingController _cardIdFieldController = TextEditingController();
  final GlobalKey<FormFieldState> _cardIdFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _propertyFieldKey =
      GlobalKey<FormFieldState>();
  StreamSubscription<String> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = serialPort.stream.listen((onData) {
      _cardIdFieldController.text = onData;
      propertyFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  bool _validId = false;
  bool _validProp = false;
  bool isBusy = false;

  validate() async {
    if (isBusy) return;
    try {
      isBusy = true;
      await app.db.register(_cardIdFieldController.value.text,
          _propertyFieldKey.currentState.value);
      _cardIdFieldController.text = "";
      _propertyFieldKey.currentState.reset();
      cardIdFocus.requestFocus();

      await showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          Future.delayed(Duration(milliseconds: 3000), () {
            Navigator.maybePop(context);
            isBusy = false;
          });
          return AlertDialog(
            content: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 40,
                  color: Colors.green.shade600,
                ),
                SizedBox(width: 10),
                Text(
                  "${tr('registrationPageTitle')} ${tr('succeeded')}",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      String trErr = tr(e.toString());
      if (trErr == null) trErr = e.toString();

      await showDialog<void>(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          Future.delayed(Duration(milliseconds: 3000), () {
            Navigator.maybePop(context);
            isBusy = false;
          });
          return AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  MaterialIcons.getIconData('warning'),
                  size: 40,
                  color: Colors.red.shade600,
                ),
                SizedBox(width: 25),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${tr('registrationPageTitle')} ${tr('failed')}",
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Flexible(
                        child: Text(
                          trErr,
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  final FocusNode cardIdFocus = FocusNode();
  final FocusNode _cardIdFocus = FocusNode();
  final FocusNode propertyFocus = FocusNode();
  final FocusNode _propertyFocus = FocusNode();

  void refresh(Function f) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) setState(f);
    });
  }

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
                      RawKeyboardListener(
                        focusNode: _cardIdFocus,
                        onKey: (event) {
                          if (event.logicalKey.keyId == 54) {
                            propertyFocus.requestFocus();
                          }
                        },
                        child: TextFormField(
                          focusNode: cardIdFocus,
                          autofocus: true,
                          autocorrect: false,
                          autovalidate: true,
                          validator: (value) {
                            // if (value.isNotEmpty) {
                            //   // Completer<String> c = Completer();
                            //   int amount = 0;
                            //   try {
                            //     amount = int.parse(value);
                            //   } catch (e) {
                            //     refresh(() => _validId = false);
                            //     return "Not a number";
                            //   }

                            //   if (amount <= 0) {
                            //     refresh(() => _validId = false);
                            //     return "Amount must be positive";
                            //   }
                            // }
                            refresh(() => _validId = value.isNotEmpty);
                            return null;
                          },
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                          key: _cardIdFieldKey,
                          controller: _cardIdFieldController,
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(tr('name'), style: TextStyle(fontSize: 40)),
                      RawKeyboardListener(
                        focusNode: _propertyFocus,
                        onKey: (event) {
                          if (event.logicalKey.keyId == 54 &&
                              (_propertyFieldKey.currentState.value as String)
                                  .isNotEmpty) {
                            validate();
                          }
                        },
                        child: TextFormField(
                          focusNode: propertyFocus,
                          autocorrect: false,
                          autovalidate: true,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                          key: _propertyFieldKey,
                          validator: (value) {
                            // if (value.isNotEmpty) {
                            //   int amount = 0;
                            //   try {
                            //     amount = int.parse(value);
                            //   } catch (e) {
                            //     refresh(() => _validProp = false);
                            //     return "Not a number";
                            //   }

                            //   if (amount <= 0) {
                            //     refresh(() => _validProp = false);
                            //     return "Amount must be positive";
                            //   }
                            // }
                            refresh(() => _validProp = value.isNotEmpty);
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 80,
                      child: MaterialButton(
                        color: Colors.lightBlue.shade100,
                        onPressed: (_validId && _validProp) ? validate : null,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
