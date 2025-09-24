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
  String parseCardNumber(String hexData, {bool validateChecksum = true}) {
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
        .map((data) => parseCardNumber(data.trim()))
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
      if (AppConfig.printerName != null)
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

  double radius() => 10;
  final FocusNode cardIdFocus = FocusNode();
  final FocusNode propertyFocus = FocusNode();
  final FocusNode _pageFocus = FocusNode();

  void refresh(Function f) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) setState(f);
    });
  }

  void _newProduct() {
    _initStateAsync = initStateAsync();
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
                      onTap: (DbRecordProduct p) => _addToCart(p),
                    );
                  },
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(children: <Widget>[
                Expanded(
                  child: Cart(
                    cartItems: cart,
                    onTapRemoveFromCart: _removeFromCart,
                    onTapAddToCart: _addToCartByIndex,
                    onChangeQuantityOfCartItem: _setQuantityOfCartItemByIndex,
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
          width: 175,
          child: TextFormField(
            enabled: false,
            decoration: InputDecoration(
              disabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
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

  void _setQuantityOfCartItemByIndex(int index, int quantity) {
    setState(() {
      cart[index].quantity = quantity;
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
              if (AppConfig.printerName != null)
                await printReqTopUp(origValue, newValue);
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
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        width: 8,
        text: "FELTÖLTÉS ELÖTTI EGYENLEG",
        containsChinese: true,
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      ),
      PosColumn(
        width: 4,
        text: "$origValue Ft",
        styles: const PosStyles(
          align: PosAlign.right,
        ),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        width: 8,
        text: "FELTÖTÖTT ÖSSZEG",
        containsChinese: true,
        styles: const PosStyles(
          align: PosAlign.left,
        ),
      ),
      PosColumn(
        width: 4,
        text: "${newValue - origValue} Ft",
        styles: const PosStyles(
          align: PosAlign.right,
        ),
      ),
    ]);

    bytes += [27, 97, 1];
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        width: 8,
        text: "ÚJ EGYENLEG",
        containsChinese: true,
        styles: const PosStyles(
          height: PosTextSize.size2,
          bold: true,
          align: PosAlign.left,
        ),
      ),
      PosColumn(
        width: 4,
        text: "$newValue Ft",
        styles: const PosStyles(
          height: PosTextSize.size2,
          bold: true,
          align: PosAlign.right,
        ),
      ),
    ]);

    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.hr(ch: '*');
    bytes += generator.feed(1);
    bytes += generator.text(
      'IDÖ : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(timeNow)}',
      containsChinese: true,
      styles: const PosStyles(
        height: PosTextSize.size2,
        bold: true,
      ),
    );

    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.text('*** Jó étvágyat kíván az ÍZGYÁR csapata! ***');

    bytes += generator.cut();

    await sendPrintRequest(bytes, AppConfig.printerName);
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
            text: "     ${item.quantity}db * ${item.product.priceHuf} Ft",
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
      'IDÖ : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(timeNow)}',
      containsChinese: true,
      styles: const PosStyles(
        height: PosTextSize.size2,
        bold: true,
      ),
    );

    bytes += generator.feed(1);

    bytes += [27, 97, 1];
    bytes += generator.text('*** Jó étvágyat kíván az ÍZGYÁR csapata! ***');

    bytes += generator.cut();

    await sendPrintRequest(bytes, AppConfig.printerName);
  }
}
