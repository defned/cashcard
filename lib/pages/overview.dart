import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cashcard/app/app_config.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/pages/topupdialog.dart';
import 'package:cashcard/util/cart.dart';
import 'package:cashcard/util/logging.dart';
import 'package:cashcard/util/serialporthelper.dart';
import 'package:cashcard/util/usbporthelper.dart';
import 'package:cashcard/widget/cart.dart';
import 'package:cashcard/widget/reportsdialog.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/app.dart';
import 'package:cashcard/widget/products.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/util/extensions.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

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

  List<DbRecordProduct> _dbProducts = [];
  List<DbRecordCategory> _dbCategories = [];

  /// Parse the card number from the reader's ASCII-hex payload.
  /// Example: "41FF0000000300975EED010098" -> "9920237"
  String parseCardNumber2(String hexData, {bool validateChecksum = true}) {
    // Keep only hex chars
    final cleaned = hexData.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.isEmpty || cleaned.length.isOdd) {
      throw ArgumentError('Invalid hex string.');
    }

    // Hex -> bytes
    final bytes = <int>[];
    for (var i = 0; i < cleaned.length; i += 2) {
      bytes.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
    }

    // Drop trailing CR (0x0D) if present
    var data = bytes;
    if (data.isNotEmpty && data.last == 0x0D) {
      data = data.sublist(0, data.length - 1);
    }

    // Need at least [c3 c2 c1 c0 c4 r0 crc] = 7 bytes
    if (data.length < 7) {
      throw ArgumentError('Too few bytes for payload.');
    }

    final r0 = data[data.length - 2];
    if (r0 != 0x00) {
      throw StateError('r0 byte is not 0x00 (got 0x${r0.toRadixString(16)}).');
    }

    if (validateChecksum) {
      var xor = 0;
      for (final b in data) xor ^= b;
      if (xor != 0) {
        throw StateError('XOR checksum failed (overall XOR != 0).');
      }
    }

    // c3..c0 are the 4 bytes immediately before c4,r0,crc
    final cBytes =
        data.sublist(data.length - 7, data.length - 3); // [c3,c2,c1,c0]

    // Big-endian: c3 is MSB, c0 is LSB
    final cardNumber =
        (cBytes[0] << 24) | (cBytes[1] << 16) | (cBytes[2] << 8) | cBytes[3];

    return cardNumber.toString();
  }

  Future<bool> _initStateAsync = Future.value(null);

  @override
  void initState() {
    super.initState();
    _subscription = serialPort.stream
        .map((data) => parseCardNumber2(data.trim()))
        .listen(loadDetails);
    _initStateAsync = initStateAsync();
  }

  Uint8List logo;
  Future<Uint8List> loadImageFromAssets(String path) async {
    final ByteData data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  Future<bool> initStateAsync() async {
    _dbProducts = await app.db.getProductAll("");
    _dbCategories = await app.db.getCategoriesAll("");
    logo = await loadImageFromAssets('assets/images/logo.png');
    return Future.value(true);
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
      await printReqReceipt(cart, origValueRaw: _balanceFieldController.text);
      resetFields();
    } catch (e) {
      showError(this.context, tr("${e.toString()}"));
    }
  }

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
  final FocusNode propertyFocus = FocusNode();
  final FocusNode _pageFocus = FocusNode();
  final FocusNode _propertyFocus = FocusNode();

  void refresh(Function f) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) setState(f);
    });
  }

  void _newProduct() {
    // setState(() {
    // _dbProducts = app.db.getProductAll("");
    _initStateAsync = initStateAsync();
    // });
    resetFields();
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
            if (isTopUpButtonActive) Expanded(child: createInfoFields()),
            if (isTopUpButtonActive)
              createButton(
                tr('topUp'),
                color: Colors.lightBlue.shade900,
                scale: 0.6,
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
          log(event.character);
        },
        child: Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                child: FutureBuilder<bool>(
                  initialData: false,
                  future: _initStateAsync,
                  builder: (context, stateInitStateAsync) {
                    if (stateInitStateAsync.data != true)
                      return Center(child: CircularProgressIndicator());
                    return Products(
                      products: _dbProducts,
                      categories: _dbCategories,
                      onNewProduct: _newProduct,
                      onTap: (DbRecordProduct p) {
                        log("Added to cart: $p");
                        _addToCart(p);
                      },
                    );
                  },
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
                    itemsChanged: cartCount,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.grey.shade900,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Összesen:',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${totalAmount.toStringAsFixed(0)} Ft',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
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
                            scale: 1.0,
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
                              scale: 1.0,
                              enabled: isPayButtonActive,
                              color: Colors.green,
                              onTap: pay,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
          width: 175,
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
        // IconButton(
        //   iconSize: 35,
        //   onPressed: () {
        //     _cardIdFieldController.text = "12312312";
        //     loadDetails(_cardIdFieldController.text);
        //   },
        //   icon: Icon(Icons.credit_card),
        // ),
        const SizedBox(width: 10),
        AutoSizeText(tr('balance'),
            minFontSize: 15, style: TextStyle(fontSize: 25)),
        SizedBox(width: 10),
        SizedBox(
          width: 150,
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
                  print(event.character);
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
  final ValueNotifier<int> cartCount = ValueNotifier<int>(0);

  void _addToCart(DbRecordProduct product) {
    setState(() {
      var existingItem = cart.firstWhere(
        (item) => item.product.id == product.id,
        orElse: () => CartItem(product: product, quantity: 0),
      );

      if (existingItem.quantity == 0) {
        cart.add(CartItem(product: product, quantity: 1));
        cartCount.value = cart.fold(0, (p, v) => p + v.quantity);
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
      cartCount.value = cart.length;
    });
    updateButtonState();
  }

  void updateButtonState() {
    setState(() {
      isPayButtonActive = (cart.length != 0);
      isTopUpButtonActive = _cardIdFieldController.text.isNotEmpty;
      isClearButtonActive = isPayButtonActive || isTopUpButtonActive;
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
            // group: group,
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
            onSuccess: () async {
              Navigator.pop(context);
              String origValue = _balanceFieldController.text;
              await loadDetails(_cardIdFieldController.text, updateOnly: true);
              String newValue = _balanceFieldController.text;
              printReqTopUp(origValue, newValue);
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

  // 0 = left, center = 1 right = 2
  printReqTopUp(String origValueRaw, String newValueRaw) async {
    int origValue = int.parse(origValueRaw.replaceAll(" Ft", ""));
    int newValue = int.parse(newValueRaw.replaceAll(" Ft", ""));
    var timeNow = DateTime.now();
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    // LOGO
    img.Image originalImage = img.decodeImage(logo);

    bytes += generator.imageRaster(originalImage, align: PosAlign.center);
    bytes += generator.feed(1);

    bytes += generator.text(
      'SIKERES FELTÖLTÉS!',
      containsChinese: true,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.feed(1);
    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.text('---- NEM ADÓÜGYI BIZONYLAT ----');
    bytes += generator.feed(1);
    bytes += generator.text('Nyugta részletezö');
    bytes += generator.text('----------------------------------------------');

    bytes += [27, 97, 2];
    bytes += generator.text('Feltöltés elötti egyenleg  $origValue Ft',
        containsChinese: true);
    bytes += generator.text('Feltötött összeg  ${newValue - origValue} Ft',
        containsChinese: true);

    bytes += [27, 97, 1];
    bytes += generator.text('----------------------------------------------');

    bytes += [27, 97, 2];
    bytes += generator.text(
      'Új egyenleg  $newValue Ft',
      containsChinese: true,
      styles: const PosStyles(
        height: PosTextSize.size2,
        bold: true,
      ),
    );

    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.text('**********************************************');
    bytes += generator.feed(1);
    bytes += generator.text(
      'Idö : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(timeNow)}',
      containsChinese: true,
      styles: const PosStyles(
        height: PosTextSize.size2,
        bold: true,
      ),
    );

    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.text('*** Jó étvágyat kíván az ÍZGYÁR csapata! ***');

    bytes += generator.feed(1);
    bytes += generator.cut();

    final res = await sendPrintRequest(bytes, AppConfig.printerName);
    String msg = "";

    if (res == "success") {
      msg = "Printed Successfully";
    } else {
      msg =
          "Failed to generate a print please make sure to use the correct printer name";
    }

    log(msg);
  }

  printReqReceipt(List<CartItem> cartItems, {String origValueRaw}) async {
    int origValue = int.tryParse(origValueRaw.replaceAll(" Ft", ""));
    print(origValue);
    var timeNow = DateTime.now();
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    // LOGO
    img.Image originalImage = img.decodeImage(logo);

    bytes += generator.imageRaster(originalImage, align: PosAlign.center);
    bytes += generator.feed(1);

    bytes += generator.text(
      'NYUGTA',
      containsChinese: true,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.feed(1);
    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.text('---- NEM ADÓÜGYI BIZONYLAT ----');
    bytes += generator.feed(1);
    bytes += generator.text('Nyugta részletezö');
    bytes += generator.hr();

    int sum = 0;
    for (CartItem item in cartItems) {
      sum += item.product.priceHuf * item.quantity;

      bytes += generator.row([
        PosColumn(
          width: 8,
          text: "${item.product.name} ${item.quantity}db",
          containsChinese: true,
          styles: const PosStyles(
            align: PosAlign.left,
          ),
        ),
        PosColumn(
          width: 4,
          text: (item.quantity == 1)
              ? "${item.product.priceHuf * item.quantity} Ft"
              : "",
          styles: const PosStyles(
            align: PosAlign.right,
          ),
        ),
      ]);

      if (item.quantity > 1) {
        bytes += generator.row([
          PosColumn(
            width: 8,
            text: "      ${item.quantity}db * ${item.product.priceHuf} Ft",
            containsChinese: true,
            styles: const PosStyles(
              align: PosAlign.left,
            ),
          ),
          PosColumn(
            width: 4,
            text: "${item.product.priceHuf * item.quantity} Ft",
            styles: const PosStyles(
              align: PosAlign.right,
            ),
          ),
        ]);
      }
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
        width: 8,
        text: "ÖSSZEG:",
        containsChinese: true,
        styles: const PosStyles(
          height: PosTextSize.size2,
          bold: true,
          align: PosAlign.left,
        ),
      ),
      PosColumn(
        width: 4,
        text: "$sum Ft",
        styles: const PosStyles(
          height: PosTextSize.size2,
          bold: true,
          align: PosAlign.right,
        ),
      ),
    ]);

    if (origValue != null) {
      bytes += generator.feed(1);
      bytes += generator.feed(1);
      bytes += [27, 97, 2];
      bytes += generator.text('Vásárlás elötti egyenleg  $origValue Ft',
          containsChinese: true);
      bytes += generator.text('Fennmaradó egyenleg  ${origValue - sum} Ft',
          containsChinese: true);
    }

    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.hr(ch: "*");
    bytes += generator.feed(1);
    bytes += generator.text(
      'Idö : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(timeNow)}',
      containsChinese: true,
      styles: const PosStyles(
        height: PosTextSize.size2,
        bold: true,
      ),
    );

    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.text('*** Jó étvágyat kíván az ÍZGYÁR csapata! ***');

    // bytes += generator.feed(1);
    bytes += generator.cut();

    final res = await sendPrintRequest(bytes, AppConfig.printerName);
    String msg = "";

    if (res == "success") {
      msg = "Printed Successfully";
    } else {
      msg =
          "Failed to generate a print please make sure to use the correct printer name";
    }

    log(msg);
  }

  // printReq() async {
  //   List<int> bytes = [];
  //   final profile = await CapabilityProfile.load();
  //   final generator = Generator(PaperSize.mm80, profile);

  //   // LOGO
  //   final Uint8List data = await loadImageFromAssets('assets/images/logo.png');
  //   img.Image originalImage = img.decodeImage(data);

  //   bytes += generator.imageRaster(originalImage, align: PosAlign.center);
  //   bytes += generator.feed(1);

  //   //GENERATE BARCODE
  //   String invoiceNo = "322123000000";
  //   List<int> barData =
  //       invoiceNo.split('').map((String digit) => int.parse(digit)).toList();

  //   bytes += generator.barcode(
  //     Barcode.itf(barData),
  //     height: 100,
  //     textPos: BarcodeText.none,
  //   );

  //   bytes += generator.feed(1);

  //   bytes += generator.text(
  //     'INV #322123000000',
  //     styles: const PosStyles(
  //       align: PosAlign.center,
  //       height: PosTextSize.size2,
  //       width: PosTextSize.size2,
  //     ),
  //   );

  //   bytes += generator.text('Reprinted at : 06-11-2023 07:32:52 AM');

  //   bytes += generator.feed(1);

  //   bytes += generator.text(
  //     'PAID(IN)',
  //     styles: const PosStyles(
  //       align: PosAlign.center,
  //       height: PosTextSize.size2,
  //       width: PosTextSize.size2,
  //     ),
  //   );

  //   bytes += generator.feed(1);

  //   bytes += generator.text('Walk in');

  //   bytes += generator.text('Tel : 0000000000');

  //   bytes += generator.text('Date\\Time : Sun, 10 Sep 2023 06:24 PM');

  //   bytes += generator.text('Associate : 5552');

  //   bytes += generator.text('Promised On : Sun, 10 Sep 2023 06:24 PM');

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: 'QTY',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //         bold: true,
  //       ),
  //     ),
  //     PosColumn(
  //       text: 'S/T/DESCRIPTION',
  //       width: 8,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //         bold: true,
  //       ),
  //     ),
  //     PosColumn(
  //       text: 'TOTAL',
  //       width: 3,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //         bold: true,
  //       ),
  //     ),
  //   ]);

  //   bytes += [27, 97, 1];
  //   bytes += generator.text('-----------------------------------------');

  //   bytes += [27, 97, 0];
  //   bytes += generator.text(
  //     ' 1x  Pants (IN)                  \$ 133.40',
  //     styles: const PosStyles(
  //       align: PosAlign.left,
  //       reverse: true,
  //       bold: true,
  //     ),
  //   );

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 1];

  //   //GENERATE BARCODE
  //   bytes += generator.barcode(
  //     Barcode.itf(
  //       "32212300000000"
  //           .split('')
  //           .map((String digit) => int.parse(digit))
  //           .toList(),
  //     ),
  //     height: 50,
  //     textPos: BarcodeText.none,
  //   );

  //   bytes += generator.text("32212300000000");

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '1x',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: '(\$13.40 Growth Hem)',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //   ]);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: '(Tag : (1x) Lengthen : Lengthen \$ 0.00',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //   ]);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: '| (1x) Lengthen : Polo Hem \$ 0.00) |',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //   ]);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: 'Dept Hem',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //         bold: true,
  //       ),
  //     ),
  //   ]);

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 0];
  //   bytes += generator.text(
  //     ' 1x  Pants (IN)                  \$ 133.40',
  //     styles: const PosStyles(
  //       align: PosAlign.left,
  //       reverse: true,
  //       bold: true,
  //     ),
  //   );

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 1];

  //   //GENERATE BARCODE
  //   bytes += generator.barcode(
  //     Barcode.itf(
  //       "32212300000000"
  //           .split('')
  //           .map((String digit) => int.parse(digit))
  //           .toList(),
  //     ),
  //     height: 50,
  //     textPos: BarcodeText.none,
  //   );

  //   bytes += generator.text("32212300000000");

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '1x',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: '(\$13.40 Growth Hem)',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //   ]);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: '(Tag : (1x) Lengthen : Lengthen \$ 0.00',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //   ]);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: '| (1x) Lengthen : Polo Hem \$ 0.00) |',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //   ]);

  //   bytes += [27, 97, 0];
  //   bytes += generator.row([
  //     PosColumn(
  //       text: '',
  //       width: 1,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //       ),
  //     ),
  //     PosColumn(
  //       text: 'Dept Hem',
  //       width: 11,
  //       styles: const PosStyles(
  //         align: PosAlign.left,
  //         bold: true,
  //       ),
  //     ),
  //   ]);

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 1];
  //   bytes += generator.text('-----------------------------------------');

  //   bytes += [27, 97, 0];
  //   bytes += generator.text(
  //     'HST # : R877439000',
  //     styles: const PosStyles(
  //       height: PosTextSize.size1,
  //     ),
  //   );

  //   bytes += [27, 97, 2];
  //   bytes += generator.text('Sub Total  \$ 13.40');

  //   bytes += [27, 97, 0];
  //   bytes += generator.text('Total Disc \$ 0.00');

  //   bytes += [27, 97, 2];
  //   bytes += generator.text('HST (13%)  \$ 1.74');

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 2];
  //   bytes += generator.text(
  //     'Total  \$ 15.14',
  //     styles: const PosStyles(
  //       height: PosTextSize.size2,
  //       bold: true,
  //     ),
  //   );

  //   bytes += generator.text(
  //     'Balance Owing  \$ 0.00',
  //     styles: const PosStyles(
  //       height: PosTextSize.size2,
  //       bold: true,
  //     ),
  //   );

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 1];
  //   bytes += generator.text('Transaction details');
  //   bytes += generator.text('*****************************************');

  //   bytes += [27, 97, 0];
  //   bytes += generator.text('Tender Type :  Cash(INV)');
  //   bytes += generator.text('Amount :  \$ 0.00');

  //   bytes += [27, 97, 2];
  //   bytes += generator.text('Total Tendered  \$ 13.40');
  //   bytes += generator.text('Total Charge  \$ 0.00');
  //   bytes += generator.text('Total Round Off  \$ 0.01');

  //   bytes += [27, 97, 0];
  //   bytes += generator.text('Items :  1');

  //   bytes += [27, 97, 1];
  //   bytes += generator.text(
  //     'Production : Sun, 10 Sep 2023 09:00 AM',
  //     styles: const PosStyles(
  //       height: PosTextSize.size2,
  //       bold: true,
  //     ),
  //   );

  //   bytes += generator.feed(1);

  //   bytes += [27, 97, 2];
  //   bytes += generator.text('Points Earned Before This Visit : \$ 739.85');
  //   bytes += generator.text('Total Points Earned :  \$ 0.57');

  //   // 0 = left, center = 1 right = 2
  //   bytes += [27, 97, 1];
  //   bytes += generator.text('*** Store Copy ***');

  //   bytes += generator.feed(1);
  //   bytes += generator.cut();

  //   print(String.fromCharCodes(bytes));
  //   // final res = await sendPrintRequest(bytes, AppConfig.printerName);
  //   var res = "success";
  //   String msg = "";

  //   if (res == "success") {
  //     msg = "Printed Successfully";
  //   } else {
  //     msg =
  //         "Failed to generate a print please make sure to use the correct printer name";
  //   }

  //   print(msg);
  // }
}
