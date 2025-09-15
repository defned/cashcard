import 'dart:async';
import 'dart:io';

import 'package:cashcard/app/app_config.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/pages/topupdialog.dart';
import 'package:cashcard/util/cart.dart';
import 'package:cashcard/util/logging.dart';
import 'package:cashcard/widget/cart.dart';
import 'package:cashcard/widget/reportsdialog.dart';
import 'package:path/path.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/app.dart';
import 'package:cashcard/widget/products.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/main.dart';
import 'package:cashcard/util/extensions.dart';
import 'package:cashcard/widget/filedialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

class OverviewPage extends StatefulWidget {
  /// Constructor
  const OverviewPage({Key key}) : super(key: key);

  @override

  /// State creator
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with StateWithLocalization<OverviewPage> {
  AutoSizeGroup group = AutoSizeGroup();

  final TextEditingController _cardIdFieldController = TextEditingController();
  final TextEditingController _balanceFieldController = TextEditingController();
  final TextEditingController _propertyFieldController =
      TextEditingController();
  final GlobalKey<FormFieldState> _cardIdFieldKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _propertyFieldKey =
      GlobalKey<FormFieldState>();

  StreamSubscription<String> _subscription;

  // Holds the text that user typed.
  String text = '';

  // True if shift enabled.
  bool shiftEnabled = false;

  // is true will show the numeric keyboard.
  bool isNumericMode = true;

  bool isBusy = false;

  Future<List<DbRecordProduct>> _dbProducts = Future.value([]);

  @override
  void initState() {
    super.initState();
    _subscription =
        serialPort.stream.map((data) => data.trim()).listen(loadDetails);
    _dbProducts = app.db.getProductAll("");
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  pay() async {
    try {
      await app.db.pay(_cardIdFieldController.text, cart);
      showInfo(this.context, "${tr('pay')} ${tr('succeeded')}");
      resetFields();
    } catch (e) {
      showError(this.context, tr("${e.toString()}"));
    }
  }

  // topUp() async {
  //   try {
  //     await app.db.topUp(_cardIdFieldController.text,
  //         int.tryParse(_propertyFieldController.text));
  //     showInfo(this.context, "${tr('topUp')} ${tr('succeeded')}");
  //     resetFields();
  //   } catch (e) {
  //     showError(this.context, tr("${e.toString()}"));
  //   }
  // }

  loadDetails(String data, {bool updateOnly = true}) async {
    if (AppConfig.transformationFrom != null) {
      final hasMatch = AppConfig.transformationFrom.hasMatch(data);

      if (hasMatch && AppConfig.transformationTo != null)
        data = data.replaceRegExp(
            AppConfig.transformationFrom, AppConfig.transformationTo);
      else if (!hasMatch) {
        log("$data id is not matching against pattern");
        showError(this.context, tr("invalidID"));
        return;
      }
    }

    try {
      DbRecordBalance record = await app.db.getBalance(data);
      if (!updateOnly) resetFields();
      _cardIdFieldController.text = data;
      _balanceFieldController.text = "${record.balance} Ft";
      updateButtonState();
    } catch (e) {
      try {
        if (e == DbExceptions.noRows) {
          await app.db.registerBalance(data);
          showInfo(this.context,
              "${tr('registrationPageTitle')} ${tr('succeeded')}");
          // resetFields();
        }

        DbRecordBalance record = await app.db.getBalance(data);

        _cardIdFieldController.text = data;
        _balanceFieldController.text = "${record.balance} Ft";
        updateButtonState();
      } catch (e) {
        showError(this.context, tr("${e.toString()}"));
      }
    }
  }

  resetFields() {
    setState(() {
      cart.clear();
      isTopUpButtonActive = false;
      _cardIdFieldController.clear();
      _balanceFieldController.clear();
      _propertyFieldController.clear();
      propertyFocus.requestFocus();
    });
    updateButtonState();
  }

  // bool _validId = false;
  bool _validProp = false;
  double radius() => 10;
  final FocusNode cardIdFocus = FocusNode();
  // final FocusNode _cardIdFocus = FocusNode();
  final FocusNode propertyFocus = FocusNode();
  final FocusNode _pageFocus = FocusNode();
  final FocusNode _propertyFocus = FocusNode();

  void refresh(Function f) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) setState(f);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Text(
              tr('title'),
              style: TextStyle(fontSize: 20),
            ),
            Expanded(child: createInfoFields()),
            createButton(
              tr('topUp'),
              color: Colors.lightBlue.shade900,
              scale: 0.5,
              onTap: showTopUp,
              enabled: isTopUpButtonActive,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.table_chart),
            onPressed: showReportsDialog,
          ),
          IconButton(
            tooltip: tr("aboutTooltip"),
            icon: Icon(Icons.info_outline),
            onPressed: showAbout,
          )
        ],
      ),
      body: RawKeyboardListener(
        autofocus: true,
        focusNode: _pageFocus,
        onKey: (event) {
          log(event);
          if (event is RawKeyDownEvent) {
            // bool isCTRL = Platform.isMacOS
            //     ? event.isMetaPressed
            //     : event.isControlPressed || event.logicalKey.keyLabel == "9";

            bool isImport = event.logicalKey.keyLabel ==
                "i" || /* What the heck?! Flutter is buggy here ... */ event
                    .logicalKey.keyLabel ==
                "\\";
            bool isExport = event.logicalKey.keyLabel ==
                "e" || /* What the heck?! Flutter is buggy here ... */ event
                    .logicalKey.keyLabel ==
                "-";

            if (/*isCTRL && */ isImport) {
              showImportDialog();
            } else if (/*isCTRL && */ isExport) {
              showExportDialog();
            }

            // if (event.logicalKey.keyId == 54 &&
            //     (_propertyFieldKey.currentState.value
            //             as String)
            //         .isNotEmpty) {
            //   validate();
            // }
          }
        },
        child: Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                child: FutureBuilder<List<DbRecordProduct>>(
                  initialData: [],
                  future: _dbProducts,
                  builder: (context, state) => Products(
                    products: state.data,
                    onTap: (DbRecordProduct p) {
                      log("Added to cart: $p");
                      _addToCart(p);
                    },
                  ),
                ),
              ),
            ),
            Container(
              // color: Colors.blue,
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(children: <Widget>[
                Expanded(
                  child: Cart(
                    cartItems: cart,
                    onTapRemoveFromCart: _removeFromCart,
                    onTapAddToCart: _addToCartByIndex,
                  ),
                ),
                Container(
                  color: Colors.grey.shade900,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Összesen:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${totalAmount.toStringAsFixed(0)} Ft',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          createButton(
                            tr('clear'),
                            color: Colors.red.shade900,
                            enabled: isClearButtonActive,
                            onTap: () {
                              _clearCart();
                              resetFields();
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: createButton(
                              tr('pay'),
                              enabled: isPayButtonActive,
                              color: Colors.green,
                              onTap: pay,
                            ),
                          ),
                          // const SizedBox(width: 15),
                        ],
                      ),
                    ],
                  ),
                ),
                // Expandable(
                //   leading: const Icon(Icons.keyboard, size: 55),
                //   // initiallyExpanded: true,
                //   children: [
                //     Row(
                //       mainAxisAlignment: MainAxisAlignment.end,
                //       children: <Widget>[
                //         createButtons(),
                //         const SizedBox(width: 15),
                //       ],
                //     ),
                //   ],
                //   title: Column(
                //     mainAxisSize: MainAxisSize.min,
                //     children: <Widget>[
                //       Row(
                //         mainAxisSize: MainAxisSize.max,
                //         children: <Widget>[
                //           createButton(
                //             tr('clear'),
                //             color: Colors.red.shade900,
                //             enabled: isClearButtonActive,
                //             onTap: () {
                //               _clearCart();
                //               resetFields();
                //             },
                //           ),
                //           const SizedBox(width: 10),
                //           Expanded(
                //             child: createButton(
                //               tr('pay'),
                //               enabled: isPayButtonActive,
                //               color: Colors.green,
                //               onTap: pay,
                //             ),
                //           ),
                //           const SizedBox(width: 15),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget createInfoFields() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(width: 10),
        AutoSizeText(tr('cardId'),
            minFontSize: 15, style: TextStyle(fontSize: 25)),
        const SizedBox(width: 10),
        SizedBox(
          width: 200,
          child: TextFormField(
            enabled: false,
            focusNode: cardIdFocus,
            cursorColor: Colors.transparent,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              disabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
            key: _cardIdFieldKey,
            controller: _cardIdFieldController,
          ),
        ),
        // NOTE: Only for test purposes
        IconButton(
          iconSize: 35,
          onPressed: () {
            _cardIdFieldController.text = "12312312";
            loadDetails(_cardIdFieldController.text);
          },
          icon: Icon(Icons.credit_card),
        ),
        const SizedBox(width: 10),
        AutoSizeText(tr('balance'),
            minFontSize: 15, style: TextStyle(fontSize: 25)),
        SizedBox(width: 10),
        SizedBox(
          width: 200,
          child: TextFormField(
            enabled: false,
            decoration: InputDecoration(
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none),
            // focusNode: cardIdFocus,
            cursorColor: Colors.transparent,
            enableSuggestions: false,
            autofocus: true,
            autocorrect: false,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
            controller: _balanceFieldController,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
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
              RawKeyboardListener(
                focusNode: _propertyFocus,
                onKey: (event) {
                  // if (event.logicalKey.keyId == 54 &&
                  //     (_propertyFieldKey.currentState.value
                  //             as String)
                  //         .isNotEmpty) {
                  //   validate();
                  // }
                },
                child: Stack(
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
                            borderSide:
                                BorderSide(color: AppColors.brightText)),
                      ),
                      controller: _propertyFieldController,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
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
                          isTopUpButtonActive = _validProp &&
                              _cardIdFieldController.text.isNotEmpty;
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
                                color: AppColors.brightText, fontSize: 45),
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
              color: Colors.black,
              borderRadius: BorderRadius.circular(radius()),
              border: Border.all(
                width: 3,
                color: AppColors.brightText,
              )),
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              VirtualKeyboard(
                  fontSize: 30,
                  textColor: AppColors.brightText,
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

  ////////////////////
  List<CartItem> cart = [];
  void _addToCart(DbRecordProduct product) {
    setState(() {
      var existingItem = cart.firstWhere(
        (item) => item.product.id == product.id,
        orElse: () => CartItem(product: product, quantity: 0),
      );

      if (existingItem.quantity == 0) {
        cart.add(CartItem(product: product, quantity: 1));
      } else {
        existingItem.quantity++;
      }
    });
    updateButtonState();
  }

  void _removeFromCart(int index) {
    setState(() {
      if (cart[index].quantity > 1) {
        cart[index].quantity--;
      } else {
        cart.removeAt(index);
      }
    });
    updateButtonState();
  }

  void _addToCartByIndex(int index) {
    setState(() {
      cart[index].quantity++;
    });
    updateButtonState();
  }

  void _clearCart() {
    setState(() {
      cart.clear();
    });
    updateButtonState();
  }

  void updateButtonState() {
    setState(() {
      isPayButtonActive = isClearButtonActive = (cart.length != 0);
      isTopUpButtonActive = _cardIdFieldController.text.isNotEmpty;
    });
  }

  double get totalAmount {
    return cart.fold(
      0,
      (sum, item) => sum + (item.product.priceHuf * item.quantity),
    );
  }

  ///
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

  bool isTopUpButtonActive = false;
  bool isClearButtonActive = false;
  bool isPayButtonActive = false;

  Widget createButton(String s,
      {Color color,
      double scale = 1,
      void Function() onTap,
      bool enabled = true}) {
    return RawMaterialButton(
      onPressed: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
            color: (color == null ? Colors.black : color),
            borderRadius: BorderRadius.circular(radius()),
            border: Border.all(
              width: 3 * scale,
              color: enabled ? AppColors.brightText : AppColors.disabledColor,
            )),
        padding: EdgeInsets.symmetric(
            horizontal: 15.0 * scale, vertical: 15.0 * scale),
        child: Center(
          child: AutoSizeText(
            s,
            style: TextStyle(
              fontSize: 35 * scale,
              color: enabled ? AppColors.brightText : AppColors.disabledColor,
            ),
            maxLines: 1,
            group: group,
          ),
        ),
      ),
    );
  }

  void showTopUp() {
    showDialog<void>(
      barrierDismissible: true,
      context: this.context,
      builder: (context) {
        return TopUpDialog(
            cardId: _cardIdFieldController.text,
            onSuccess: () {
              Navigator.pop(context);
              loadDetails(_cardIdFieldController.text, updateOnly: true);
              Future.delayed(
                  Duration(milliseconds: 250),
                  () => showInfo(
                      this.context, "${tr('topUp')} ${tr('succeeded')}"));
            });
      },
    );
  }

  void showReportsDialog() {
    showDialog<void>(
        barrierDismissible: true,
        context: this.context,
        builder: (context) {
          return ReportsDialog();
        });
  }

  void showAbout() {
    showDialog<void>(
      barrierDismissible: true,
      context: this.context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.black,
                  size: 100,
                ),
                SizedBox(width: 25),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                        text: "${tr('author')}: ",
                        children: [
                          TextSpan(
                              text: "${tr('authorName')}",
                              style: TextStyle(
                                  fontSize: 21,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900)),
                        ],
                        style: TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                        text: "${tr('email')}: ",
                        children: [
                          TextSpan(
                              text: "${tr('authorEmail')}",
                              style: TextStyle(
                                  fontSize: 21,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900)),
                        ],
                        style: TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                      SizedBox(height: 5),
                      RichText(
                          text: TextSpan(
                        text: "${tr('version')}: ",
                        children: [
                          TextSpan(
                              text: "${tr('versionNumber')}",
                              style: TextStyle(
                                  fontSize: 21,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900)),
                        ],
                        style: TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      )),
                      SizedBox(height: 10),
                      Text(
                        "${tr('about')}",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  showImportDialog() {
    showDialog<void>(
      barrierDismissible: false,
      context: this.context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade200,
          content: Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 2,
            child: Theme(
              data: whiteTheme(),
              child: FileDialog(
                title: tr('importAction'),
                onOpen: (fs) async {
                  List<DbRecordBalance> records = [];
                  try {
                    records = serializeRecordsFromCSV(fs);
                    await app.db.insertBalances(records);
                    showInfo(this.context,
                        "${tr('importAction')} ${tr('succeeded')} ${records.length}/${records.length}");
                  } catch (e) {
                    showError(
                        this.context, "${tr('importAction')} ${tr('failed')}");
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  showExportDialog() {
    final DbRecordDataSource _dbRecordsDataSource = DbRecordDataSource()
      ..init("");
    showDialog<void>(
      barrierDismissible: false,
      context: this.context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade200,
          content: Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 2,
            child: Theme(
              data: whiteTheme(),
              child: FileDialog(
                title: tr('exportAction'),
                target: FileDialogTarget.DIRECTORY,
                onOpen: (dir) async {
                  List<DbRecordBalance> records =
                      _dbRecordsDataSource.getBalanceRecords();
                  String serializedRecords =
                      serializeRecordsIntoCSV(records).join("\n");
                  File exportFile = File(join(dir.absolute.path,
                      "export-${DateTime.now().toIso8601String().replaceAll(".", "").replaceAll(":", "").replaceAll("-", "").replaceAll(" ", "")}.csv"));
                  exportFile.writeAsStringSync(serializedRecords);
                  log("Export succeeded to '${exportFile.absolute.path}'");
                  showInfo(this.context,
                      "${tr('exportAction')} ${tr('succeeded')} ${records.length}/${records.length}");
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<DbRecordBalance> serializeRecordsFromCSV(FileSystemEntity fs) {
    if (fs is! File) throw tr('invalidImportSource');

    List<String> lines = (fs as File).readAsLinesSync();
    String firstLine = lines.first.toUpperCase();
    Map<String, int> columnIds = {
      'ID': 0,
      'BALANCE': 0,
    };
    if (!firstLine.contains(';')) throw tr('invalidImportFormat');

    // Remapping indexes if needed
    List<String> header = firstLine.split(';');
    bool hasHeader = false;
    if (firstLine.contains('ID')) {
      columnIds['ID'] = header.indexOf('ID');
      columnIds['BALANCE'] = header.indexOf('BALANCE');
      hasHeader = true;
    }

    List<DbRecordBalance> res = [];
    for (var i = hasHeader ? 1 : 0; i < lines.length; i++) {
      List<String> splitted = lines[i].split(';');
      if (splitted.length != header.length) {
        log(tr('malformedInput'));
        continue;
      }

      if (splitted[columnIds['ID']].isEmpty) {
        log("Skipped record due to missing or empty property '${[
          splitted[columnIds['ID']]
        ]}'");
        continue;
      }

      res.add(DbRecordBalance(
        splitted[columnIds['ID']],
        columnIds['BALANCE'] == -1
            ? null
            : int.tryParse(splitted[columnIds['BALANCE']]),
      ));
    }

    return res;
  }

  List<String> serializeRecordsIntoCSV(List<DbRecordBalance> records) {
    const String SEP = ";";

    List<String> res = ['ID${SEP}BALANCE$SEP'];
    records.forEach((record) {
      res.add("${record.id}$SEP${record.balance}$SEP");
    });

    return res;
  }
}
