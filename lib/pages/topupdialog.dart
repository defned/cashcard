import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/util/extensions.dart';
import 'package:cashcard/app/app.dart';
import 'package:flutter/material.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

class TopUpDialog extends StatefulWidget {
  final String cardId;
  final Function onSuccess;
  TopUpDialog({Key key, this.cardId, this.onSuccess}) : super(key: key);

  @override
  _TopUpDialogState createState() => _TopUpDialogState();
}

class _TopUpDialogState extends State<TopUpDialog>
    with StateWithLocalization<TopUpDialog> {
  final FocusNode propertyFocus = FocusNode();

  AutoSizeGroup group = AutoSizeGroup();
  final TextEditingController _propertyFieldController =
      TextEditingController();
  // Holds the text that user typed.
  String text = '';

  // True if shift enabled.
  bool shiftEnabled = false;

  double radius() => 10;
  bool _validProp = false;
  bool isButtonsActive = true;
  final GlobalKey<FormFieldState> _propertyFieldKey =
      GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('topUp'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 32,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Container(
            height: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(widget.cardId.isEmpty ? "NaN" : widget.cardId,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.green.shade900,
                    )),
                createBalanceInput(),
                createButtons(),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          Container(
            width: 200,
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 3,
                    color: isButtonsActive
                        ? AppColors.brightText
                        : AppColors.disabledColor,
                  ),
                  borderRadius: BorderRadius.circular(radius())),
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              onPressed: () => topUp(context),
              child: Text(
                tr('topUp'),
                style: TextStyle(fontSize: 23),
              ),
              color: Colors.lightBlue.shade900,
            ),
          ),
          Container(
            width: 200,
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 3,
                    color: isButtonsActive
                        ? AppColors.brightText
                        : AppColors.disabledColor,
                  ),
                  borderRadius: BorderRadius.circular(radius())),
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('cancel'),
                style: TextStyle(fontSize: 23),
              ),
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void refresh(Function f) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) setState(f);
    });
  }

  Widget createBalanceInput() {
    return Expanded(
      child: Column(
        children: <Widget>[
          const SizedBox(height: 15),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(tr('amount'), style: TextStyle(fontSize: 30)),
              Stack(
                children: <Widget>[
                  TextFormField(
                    enabled: false,
                    cursorColor: Colors.transparent,
                    focusNode: propertyFocus,
                    autocorrect: false,
                    autovalidate: true,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      disabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.darkText)),
                    ),
                    controller: _propertyFieldController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                    key: _propertyFieldKey,
                    validator: (value) {
                      if (value.isNotEmpty) {
                        int amount = 0;
                        try {
                          amount = int.parse(value);
                        } catch (e) {
                          refresh(() => _validProp = false);
                          return tr("notNumber");
                        }

                        if (amount <= 0) {
                          refresh(() => _validProp = false);
                          return tr("mustBePositive");
                        }
                      }
                      refresh(() {
                        _validProp = value.isNotEmpty;
                        isButtonsActive =
                            _validProp && widget.cardId.isNotEmpty;
                      });
                      return null;
                    },
                  ),
                  if (_propertyFieldController.text.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          "Ft",
                          style: TextStyle(
                              color: AppColors.darkText, fontSize: 45),
                        ),
                      ),
                    ),
                  if (_propertyFieldController.text.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: IconButton(
                          iconSize: 35,
                          onPressed: () {
                            Future.delayed(Duration(milliseconds: 50))
                                .then((_) {
                              setState(() {
                                _propertyFieldController.clear();
                              });
                            });
                          },
                          icon: Icon(Icons.clear),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget createButtons() {
    return Container(
      constraints: BoxConstraints(maxWidth: 485),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(radius()),
              border: Border.all(
                width: 3,
                color: AppColors.darkText,
              )),
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              VirtualKeyboard(
                  fontSize: 30,
                  textColor: AppColors.darkText,
                  height: 200,
                  type: VirtualKeyboardType.Numeric,
                  onKeyPress: _onKeyPress),
              SizedBox(height: 20),
            ],
          ),
        ),
      ]),
    );
  }

  void setValue(int value) {
    // Update the screen
    TextEditingController ctrl = _propertyFieldController;
    ctrl.text = value.toString();
    setState(() {
      if (ctrl == _propertyFieldController) {}
    });
  }

  /// Fired when the virtual keyboard key is pressed.
  _onKeyPress(VirtualKeyboardKey key) {
    TextEditingController ctrl;
    ctrl = _propertyFieldController;

    if (key.keyType == VirtualKeyboardKeyType.String) {
      ctrl.text = ctrl.text + (shiftEnabled ? key.capsText : key.text);
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          if (ctrl.text.length == 0) return;
          ctrl.text = ctrl.text.substring(0, ctrl.text.length - 1);
          // if (text.length == 0) return;
          // text = text.substring(0, text.length - 1);
          break;
        case VirtualKeyboardKeyAction.Return:
          ctrl.text = ctrl.text + '\n';
          // text = text + '\n';
          break;
        case VirtualKeyboardKeyAction.Space:
          ctrl.text = ctrl.text + key.text;
          // text = text + key.text;
          break;
        case VirtualKeyboardKeyAction.Shift:
          shiftEnabled = !shiftEnabled;
          break;
        default:
      }
    }
    // Update the screen
    setState(() {
      if (ctrl == _propertyFieldController) {}
    });
  }

  Widget createButton(String s,
      {Color color, double scale = 1, void Function() onTap}) {
    return RawMaterialButton(
      onPressed: isButtonsActive ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
            color: (color == null ? Colors.black : color),
            borderRadius: BorderRadius.circular(radius()),
            border: Border.all(
              width: 3 * scale,
              color: isButtonsActive
                  ? AppColors.brightText
                  : AppColors.disabledColor,
            )),
        padding: EdgeInsets.symmetric(
            horizontal: 15.0 * scale, vertical: 15.0 * scale),
        child: Center(
          child: AutoSizeText(
            s,
            style: TextStyle(
              fontSize: 35 * scale,
              color: isButtonsActive
                  ? AppColors.brightText
                  : AppColors.disabledColor,
            ),
            maxLines: 1,
            group: group,
          ),
        ),
      ),
    );
  }

  topUp(BuildContext context) async {
    try {
      await app.db
          .topUp(widget.cardId, int.tryParse(_propertyFieldController.text));
      resetFields();
      if (widget.onSuccess != null) widget.onSuccess();
    } catch (e) {
      showError(this.context, tr("${e.toString()}"));
    }
  }

  resetFields() {
    setState(() {
      _propertyFieldController.clear();
      propertyFocus.requestFocus();
    });
  }
}
