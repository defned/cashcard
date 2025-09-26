import 'dart:collection';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/app.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/util/extensions.dart';
import 'package:cashcard/util/logging.dart';
import 'package:flutter/material.dart';

class Products extends StatefulWidget {
  final Function onTap;
  final Function onNewProduct;
  final List<DbRecordProduct> products;
  final List<DbRecordCategory> categories;
  Products({
    Key key,
    this.products,
    this.categories,
    this.onTap,
    this.onNewProduct,
  }) : super(key: key);

  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products>
    with StateWithLocalization<Products>, SingleTickerProviderStateMixin {
  AutoSizeGroup _groupName = AutoSizeGroup();
  AutoSizeGroup _groupPrice = AutoSizeGroup();
  TabController _tabController;
  DbRecordProduct _refData;

  int searchCategory;
  String searchQuery = "";
  List<DbRecordProduct> selectedProducts = [];

  List<DbRecordProduct> baseProducts = [];
  List<DbRecordCategory> baseCategories = [];
  HashMap<int, List<DbRecordProduct>> grouppedProducts = HashMap();

  @override
  void didUpdateWidget(covariant Products oldWidget) {
    prepareVars();
    super.didUpdateWidget(oldWidget);
  }

  void _setState() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _propertyFieldController.addListener(_setState);
    _tabController =
        TabController(length: grouppedProducts.keys.length, vsync: this);
    prepareVars();
    selectedProducts = grouppedProducts[null];
  }

  void prepareVars() {
    if (widget.products != null) {
      baseProducts.clear();
      baseProducts.addAll(widget.products);

      baseProducts.sort((DbRecordProduct a, DbRecordProduct b) {
        if (a.favourite && !b.favourite)
          return -1;
        else if (!a.favourite && b.favourite) return 1;

        return Comparable.compare(a.name, b.name);
      });

      grouppedProducts = HashMap();
      for (var p in baseProducts) {
        grouppedProducts.putIfAbsent(p.category.id, () => []).add(p);
        // all
        grouppedProducts.putIfAbsent(null, () => []).add(p);
        // favs
        if (p.favourite) grouppedProducts.putIfAbsent(-1, () => []).add(p);
      }
      // Find the longest string
      for (var item in baseProducts) {
        if (_refData == null)
          _refData = item;
        else {
          if (_refData.name.length < item.name.length) _refData = item;
        }
      }

      baseCategories = [];
      baseCategories.addAll([
        DbRecordCategory(null, "", "#000000"),
        DbRecordCategory(-1, "", "#123123"),
      ]);
      if (widget.categories != null) {
        for (var k in widget.categories)
          if (grouppedProducts.containsKey(k.id) &&
              grouppedProducts[k.id].length > 0) baseCategories.add(k);
      }
      // selectedGroupId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _propertyFieldController.removeListener(_setState);
    _tabController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  int selectedGroupId;

  void _showNewProductDialog(String barcode) {
    String code = barcode;
    String name = '';
    int price = 0;
    bool favourite = false;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          backgroundColor: Colors.grey.shade200,
          title: Text('Új termék felvétele'),
          content: Container(
            width: MediaQuery.of(context).size.width / 2,
            child: StatefulBuilder(
              builder: (context, setDialogState) => Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Vonalkód'),
                      controller: TextEditingController(text: code),
                      onChanged: (value) => code = value,
                      // enabled: false,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Termék neve'),
                      onChanged: (value) => name = value,
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kérlek írj be érvényes termék nevet';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Ár (Ft)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => price = int.tryParse(value) ?? 0,
                      validator: (value) {
                        var parsedValue = int.tryParse(value);
                        if (parsedValue == null || parsedValue < 0) {
                          return 'Kérlek írj be érvényes árat';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Text("Kedvenc"),
                        StatefulBuilder(builder: (context, setState) {
                          return Checkbox(
                            value: favourite,
                            onChanged: (value) => setState(() {
                              favourite = value;
                            }),
                          );
                        }),
                      ],
                    ),
                    DropdownButtonFormField<int>(
                      hint: Text('Válassz csoportot'),
                      value: selectedGroupId,
                      isExpanded: true,
                      validator: (value) {
                        if (value == null) {
                          return 'Kérlek válassz egy csoportot';
                        }
                        return null;
                      },
                      items: widget.categories.map((group) {
                        return DropdownMenuItem<int>(
                          value: group.id,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                color: Color(
                                  int.parse(
                                      group.color.replaceAll('#', '0xFF')),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(group.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGroupId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            MaterialButton(
              onPressed: () async {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState != null &&
                    _formKey.currentState.validate()) {
                  if (name.isNotEmpty && price > 0) {
                    try {
                      await app.db.registerProduct(code == "" ? null : code,
                          name, price, favourite, selectedGroupId);
                      showInfo(this.context,
                          "${tr('createProductAction')} ${tr('succeeded')}");
                      Future.delayed(Duration(milliseconds: 2000), () {
                        Navigator.of(context).pop();
                        widget.onNewProduct();
                      });
                    } catch (e) {
                      showError(this.context,
                          "${tr('createProductAction')} ${tr('failed')}: $e");
                    }
                  }
                }
              },
              color: Colors.green,
              child: Row(
                children: <Widget>[
                  Icon(Icons.save, color: Colors.black),
                  Text(
                    'Mentés',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            MaterialButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('close')),
            ),
          ],
        ),
      ),
    );
  }

  void _openWindowsKeyboardViaOSK() {
    if (Platform.isWindows) {
      Process.start('osk.exe', [],
          mode: ProcessStartMode.detached, runInShell: true);
    } else {
      log('This command is for Windows only.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_propertyFieldController.text.isNotEmpty)
      selectedProducts = grouppedProducts[null];
    else
      selectedProducts = grouppedProducts[searchCategory];

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Row(
          children: <Widget>[
            ActionChip(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 3, color: AppColors.brightText),
                  borderRadius: BorderRadius.circular(10),
                ),
                label: Text("+", style: TextStyle(fontSize: 32)),
                backgroundColor: Colors.green.withAlpha(100),
                onPressed: () {
                  _showNewProductDialog("");
                }),
            const SizedBox(width: 15),
            Expanded(child: createBalanceInput()),
            const SizedBox(width: 10),
            ActionChip(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 3, color: AppColors.brightText),
                  borderRadius: BorderRadius.circular(10),
                ),
                label: Icon(Icons.keyboard, size: 32),
                backgroundColor: Colors.green.withAlpha(100),
                onPressed: () {
                  _openWindowsKeyboardViaOSK();
                }),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 65,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: baseCategories.map((category) {
              Widget label =
                  Text(category.name, style: TextStyle(fontSize: 22));
              if (category.id == null)
                label = Text(tr("all"), style: TextStyle(fontSize: 22));
              else if (category.id == -1)
                label = Icon(Icons.star,
                    color: Colors.orange.withAlpha(200), size: 28);

              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: ActionChip(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 3,
                          color: category.id == searchCategory
                              ? AppColors.brightText
                              : AppColors.disabledColor,
                        ),
                        borderRadius: BorderRadius.circular(10)),
                    label:
                        Padding(padding: const EdgeInsets.all(8), child: label),
                    backgroundColor:
                        Color(int.parse(category.color.replaceAll('#', '0xFF')))
                            .withAlpha(100),
                    onPressed: () {
                      // print("Category selected ${category.id}");
                      setState(() {
                        searchCategory = category.id;
                        selectedProducts = grouppedProducts[category.id];
                      });
                    }),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Wrap(
              runSpacing: 15,
              spacing: 15,
              direction: Axis.horizontal,
              children: selectedProducts.where((p) {
                bool res = true;
                if (_propertyFieldController.text != "" &&
                    !(p.name.toLowerCase().contains(
                            _propertyFieldController.text.toLowerCase()) ||
                        (p.code != null &&
                            p.code.toLowerCase().contains(
                                _propertyFieldController.text.toLowerCase()))))
                  res = false;
                return res;
              }).map<Widget>((p) {
                return ProductCard(
                  data: p,
                  refData: _refData,
                  onTap: () {
                    if (widget.onTap != null) widget.onTap(p);
                  },
                  groupName: _groupName,
                  groupPrice: _groupPrice,
                );
              }).toList(),
            ),
          ),
        )
      ],
    );
  }

  TextEditingController _propertyFieldController = TextEditingController();
  final GlobalKey<FormFieldState> _propertyFieldKey =
      GlobalKey<FormFieldState>();
  final FocusNode propertyFocus = FocusNode();
  void refresh(Function f) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) setState(f);
    });
  }

  Widget createBalanceInput() {
    return Stack(
      children: <Widget>[
        TextFormField(
          cursorColor: Colors.transparent,
          focusNode: propertyFocus,
          autocorrect: false,
          autovalidate: true,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: tr("search"),
            prefixIcon: Icon(Icons.search, size: 36),
            border: OutlineInputBorder(),
          ),
          controller: _propertyFieldController,
          // textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.yellow,
          ),
          key: _propertyFieldKey,
        ),
        if (_propertyFieldController.text.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: IconButton(
                iconSize: 36,
                onPressed: _propertyFieldController.clear,
                icon: Icon(Icons.clear),
              ),
            ),
          ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Function onTap;
  final DbRecordProduct data;
  final DbRecordProduct refData;
  final AutoSizeGroup groupName;
  final AutoSizeGroup groupPrice;
  ProductCard({
    Key key,
    this.data,
    this.refData,
    this.onTap,
    this.groupName,
    this.groupPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: RawMaterialButton(
        onPressed: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: data.favourite
                  ? Colors.green.shade900.withAlpha(100)
                  : Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                width: 3,
                color: AppColors.brightText,
              )),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: Center(
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Center(
                      child: AutoSizeText(
                          refData == null ? data.name : refData.name,
                          maxLines: 2,
                          wrapWords: true,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          minFontSize: 20,
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.transparent,
                          ),
                          group: groupName),
                    ),
                    Center(
                      child: AutoSizeText(data.name,
                          maxLines: 2,
                          wrapWords: true,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          minFontSize: 20,
                          style: TextStyle(
                            fontSize: 32,
                            color: AppColors.brightText,
                          ),
                          group: groupName),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AutoSizeText('${data.priceHuf} Ft',
                    maxLines: 1,
                    wrapWords: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade100,
                    ),
                    group: groupPrice),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
