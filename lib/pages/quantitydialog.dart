import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

class QuantityDialog extends StatefulWidget {
  final int quantity;
  final Function(int) onSuccess;
  QuantityDialog({Key key, this.quantity, this.onSuccess}) : super(key: key);

  @override
  _QuantityDialogState createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog>
    with StateWithLocalization<QuantityDialog> {
  final FocusNode propertyFocus = FocusNode();

  AutoSizeGroup group = AutoSizeGroup();
  TextEditingController _propertyFieldController;
  // True if shift enabled.
  bool shiftEnabled = false;

  double radius() => 10;
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState> _propertyFieldKey =
      GlobalKey<FormFieldState>();

  @override
  void initState() {
    _propertyFieldController =
        TextEditingController(text: widget.quantity?.toString());
    _propertyFieldController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _propertyFieldController.value.text.length);
    super.initState();
  }

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
              tr('quantityTitle'),
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
        content: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Container(
              height: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  createBalanceInput(),
                  createButtons(),
                ],
              ),
            ),
          ),
        ),
        actions: <Widget>[
          Container(
            width: 200,
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  side: BorderSide(width: 3, color: AppColors.disabledColor),
                  borderRadius: BorderRadius.circular(radius())),
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              onPressed: () {
                if (_formKey.currentState != null &&
                    _formKey.currentState.validate()) {
                  if (widget.onSuccess != null)
                    widget.onSuccess(int.parse(_propertyFieldController.text));
                  Navigator.of(context).maybePop();
                }
              },
              child: Text(tr('setAction'),
                  style: TextStyle(fontSize: 23, color: Colors.black)),
              color: Colors.green,
            ),
          ),
          Container(
            width: 200,
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                  side: BorderSide(width: 3, color: AppColors.disabledColor),
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
              Text(tr('quantity'), style: TextStyle(fontSize: 30)),
              Stack(
                children: <Widget>[
                  TextFormField(
                    readOnly: true,
                    focusNode: propertyFocus,
                    autocorrect: false,
                    autovalidate: true,
                    enableSuggestions: false,
                    controller: _propertyFieldController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                    key: _propertyFieldKey,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Adjon meg egy érvényes mennyiséget";
                      } else if (value.isNotEmpty) {
                        int amount = 0;
                        try {
                          amount = int.parse(value);
                        } catch (e) {
                          return tr("notNumber");
                        }

                        if (amount <= 0) {
                          return tr("quantityMustBePositive");
                        }
                      }
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
                          "db",
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

  /// Fired when the virtual keyboard key is pressed.
  _onKeyPress(VirtualKeyboardKey key) {
    TextEditingController ctrl = _propertyFieldController;
    if (key.keyType == VirtualKeyboardKeyType.String) {
      if (ctrl.selection.start != -1) {
        var before = ctrl.selection.textBefore(ctrl.text);
        // var inside = ctrl.selection.textInside(ctrl.text);
        var after = ctrl.selection.textAfter(ctrl.text);
        ctrl.text = before + key.text + after;
      } else
        ctrl.text = ctrl.text + key.text;
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          if (ctrl.text.length == 0) return;
          ctrl.text = ctrl.text.substring(0, ctrl.text.length - 1);
          break;
        default:
      }
    }
    // Update the screen
    setState(() {
      if (ctrl == _propertyFieldController) {}
    });
  }

  resetFields() {
    setState(() {
      _propertyFieldController.clear();
      propertyFocus.requestFocus();
    });
  }
}
