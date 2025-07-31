import 'package:auto_size_text/auto_size_text.dart';
import 'package:example_flutter/app/style.dart';
import 'package:example_flutter/db/db.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:example_flutter/util/logging.dart';
import 'package:flutter/material.dart';

class Products extends StatefulWidget {
  final Function onTap;
  final List<DbRecordProduct> products;
  Products({Key key, this.products, this.onTap}) : super(key: key);

  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products>
    with StateWithLocalization<Products> {
  AutoSizeGroup _groupName = AutoSizeGroup();
  AutoSizeGroup _grouPrice = AutoSizeGroup();
  DbRecordProduct _refData;

  @override
  void didUpdateWidget(covariant Products oldWidget) {
    if (oldWidget.products.length != widget.products.length) {
      widget.products.sort((DbRecordProduct a, DbRecordProduct b) {
        if (a.favourite && !b.favourite)
          return -1;
        else if (!a.favourite && b.favourite) return 1;

        return Comparable.compare(a.name, b.name);
      });
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Wrap(
        runSpacing: 15,
        spacing: 15,
        direction: Axis.horizontal,
        children: widget.products.map<Widget>((p) {
          return ProductCard(
            data: p,
            refData: _refData,
            onTap: () {
              log(p);
              if (widget.onTap != null) widget.onTap(p);
            },
            groupName: _groupName,
            groupPrice: _grouPrice,
          );
        }).toList(),
      ),
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
                      fontSize: 9,
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
