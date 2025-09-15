import 'dart:collection';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cashcard/app/style.dart';
import 'package:cashcard/db/db.dart';
import 'package:cashcard/util/extensions.dart';
// import 'package:cashcard/db/db.dart';
import 'package:flutter/material.dart';

class Products extends StatefulWidget {
  final Function onTap;
  final List<DbRecordProduct> products;
  Products({Key key, this.products, this.onTap}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        createBalanceInput(),
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
                        p.code.toLowerCase().contains(
                            _propertyFieldController.text.toLowerCase())))
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
