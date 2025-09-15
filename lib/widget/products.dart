import 'dart:collection';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/app.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/util/extensions.dart';
// import 'package:cashcard/db/db.dart';
import 'package:flutter/material.dart';

class Products extends StatefulWidget {
  final Function onTap;
  final Function onNewProduct;
  final List<DbRecordProduct> products;
  Products({Key key, this.products, this.onTap, this.onNewProduct})
      : super(key: key);

  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products>
    with StateWithLocalization<Products>, SingleTickerProviderStateMixin {
  AutoSizeGroup _groupName = AutoSizeGroup();
  AutoSizeGroup _groupPrice = AutoSizeGroup();
  TabController _tabController;
  DbRecordProduct _refData;
  HashMap<int, List<DbRecordProduct>> grouppedProducts = HashMap();
  List<DbRecordCategory> categories = [];

  @override
  void didUpdateWidget(covariant Products oldWidget) {
    if (widget.products != null &&
        oldWidget.products.length != widget.products.length) {
      widget.products.sort((DbRecordProduct a, DbRecordProduct b) {
        if (a.favourite && !b.favourite)
          return -1;
        else if (!a.favourite && b.favourite) return 1;

        return Comparable.compare(a.name, b.name);
      });

      grouppedProducts = HashMap();
      for (var p in widget.products) {
        grouppedProducts.putIfAbsent(p.category.id, () => []).add(p);
        // all
        products = grouppedProducts.putIfAbsent(null, () => []);
        products.add(p);
        // favs
        if (p.favourite) grouppedProducts.putIfAbsent(-1, () => []).add(p);
      }

      categories = [];
      categories.addAll([
        DbRecordCategory(null, tr("all"), "#000000"),
        DbRecordCategory(-1, tr("favourites"), "#123123"),
      ]);
      for (var k in grouppedProducts.keys) {
        if (k != null && k != -1)
          categories.add(grouppedProducts[k].first.category);
      }

      // Find the longest string
      for (var item in widget.products) {
        if (_refData == null)
          _refData = item;
        else {
          if (_refData.name.length < item.name.length) _refData = item;
        }
      }
    }
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
  }

  @override
  void dispose() {
    _propertyFieldController.removeListener(_setState);
    _tabController.dispose();
    super.dispose();
  }

  int searchCategory = null;
  String searchQuery = "";
  List<DbRecordProduct> products = [];

  void _showNewProductDialog(String barcode) {
    String code = barcode;
    String name = '';
    int price = 0;
    bool favourite = false;
    int selectedGroupId;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.light(),
        child: AlertDialog(
          title: Text('Új termék felvétele'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Vonalkód'),
                  controller: TextEditingController(text: code),
                  onChanged: (value) => code = value,
                  // enabled: false,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Termék neve'),
                  onChanged: (value) => name = value,
                  autofocus: true,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Ár (Ft)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => price = int.tryParse(value) ?? 0,
                ),
                Row(
                  children: <Widget>[
                    Text("Kedvenc"),
                    StatefulBuilder(builder: (context, setState) {
                      return Checkbox(
                        value: favourite,
                        // decoration: InputDecoration(labelText: 'Ár (Ft)'),
                        // keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() {
                          favourite = value;
                        }),
                      );
                    }),
                  ],
                ),
                SizedBox(height: 10),
                DropdownButton<int>(
                  hint: Text('Válassz csoportot'),
                  value: selectedGroupId,
                  isExpanded: true,
                  items: categories
                      .where((c) => (c.id != null && c.id >= 0))
                      .map((group) {
                    return DropdownMenuItem<int>(
                      value: group.id,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            color: Color(
                              int.parse(group.color.replaceAll('#', '0xFF')),
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
          actions: [
            MaterialButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Mégse'),
            ),
            MaterialButton(
              onPressed: () async {
                if (name.isNotEmpty && price > 0) {
                  try {
                    await app.db.registerProduct(code == "" ? null : code, name,
                        price, favourite, selectedGroupId);
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
                // if (name.isNotEmpty && price > 0) {
                //   try {
                //     final conn = await DatabaseService.getConnection();
                //     await conn.query(
                //       'INSERT INTO products (barcode, name, price, group_id) VALUES (?, ?, ?, ?)',
                //       [barcode, name, price, selectedGroupId],
                //     );
                //     Navigator.pop(context);
                //     _loadProducts();
                //     _processBarcodeRead(barcode);
                //   } catch (e) {
                //     _showError('Termék mentési hiba: $e');
                //   }
                // }
              },
              child: Text('Mentés'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Row(
          children: <Widget>[
            ActionChip(
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 3,
                      color: AppColors.brightText,
                    ),
                    borderRadius: BorderRadius.circular(10)),
                label: Text("+", style: TextStyle(fontSize: 26)),
                backgroundColor: Colors.green.withAlpha(100),
                onPressed: () {
                  _showNewProductDialog("");
                }),
            const SizedBox(width: 5),
            Expanded(child: createBalanceInput()),
            const SizedBox(width: 50),
          ],
        ),
        Container(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((category) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ActionChip(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 3,
                          color: category.id == searchCategory
                              ? AppColors.brightText
                              : AppColors.disabledColor,
                        ),
                        borderRadius: BorderRadius.circular(10)),
                    label: Text(category.name),
                    backgroundColor:
                        Color(int.parse(category.color.replaceAll('#', '0xFF')))
                            .withAlpha(100),
                    onPressed: () {
                      // print("Category selected ${category.id}");
                      setState(() {
                        searchCategory = category.id;
                        products = grouppedProducts[category.id];
                      });
                    }),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Wrap(
              runSpacing: 15,
              spacing: 15,
              direction: Axis.horizontal,
              children: products.where((p) {
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
                  ? Colors.green.shade900.withOpacity(0.5)
                  : Colors.black,
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
                          wrapWords: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.transparent,
                          ),
                          group: groupName),
                    ),
                    Center(
                      child: AutoSizeText(data.name,
                          maxLines: 2,
                          wrapWords: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
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
                      color: AppColors.brightText,
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
