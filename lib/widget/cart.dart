import 'package:cashcard/app/style.dart';
import 'package:cashcard/pages/quantitydialog.dart';
import 'package:cashcard/util/cart.dart';
import 'package:flutter/material.dart';

class Cart extends StatefulWidget {
  final Function(int) onTapRemoveFromCart;
  final Function(int) onTapAddToCart;
  final Function(int, int) onChangeQuantityOfCartItem;
  final ValueNotifier<int> itemsChanged;
  final List<CartItem> cartItems;
  Cart({
    Key key,
    this.cartItems,
    this.onTapRemoveFromCart,
    this.onTapAddToCart,
    this.onChangeQuantityOfCartItem,
    this.itemsChanged,
  }) : super(key: key);
  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  void scrollToBottom() {
    if (_scrollController != null)
      setState(() {
        _scrollController
            .jumpTo(_scrollController.position.maxScrollExtent + 100);
      });
  }

  @override
  void initState() {
    if (widget.itemsChanged != null)
      widget.itemsChanged.addListener(scrollToBottom);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.itemsChanged != null)
      widget.itemsChanged.removeListener(scrollToBottom);
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.grey.shade900,
        ),
        child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.cartItems.length,
            itemBuilder: (context, index) {
              var item = widget.cartItems[index];
              return Container(
                decoration: index == 0
                    ? null
                    : BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade800))),
                child: ListTile(
                  title:
                      Text(item.product.name, style: TextStyle(fontSize: 22)),
                  subtitle: Text("${item.product.priceHuf} Ft",
                      style: TextStyle(fontSize: 26)),
                  leading:
                      // Container(color: Colors.yellow, width: 40, height: 40),
                      SizedBox(
                    width: 50,
                    child: MaterialButton(
                      color: Colors.red.shade900.withAlpha(100),
                      padding: const EdgeInsets.symmetric(
                          vertical: 13, horizontal: 0),
                      shape: RoundedRectangleBorder(
                          side:
                              BorderSide(width: 3, color: AppColors.brightText),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Icon(Icons.remove_shopping_cart, size: 26),
                      onPressed: () =>
                          widget.onChangeQuantityOfCartItem(index, 0),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 3, color: AppColors.brightText),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: IconButton(
                          iconSize: 36,
                          icon: Icon(Icons.remove, size: 36),
                          onPressed: () => widget.onTapRemoveFromCart(index),
                        ),
                      ),
                      const SizedBox(width: 10),
                      MaterialButton(
                        padding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 8),
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 3, color: AppColors.brightText),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: Text('${item.quantity}x',
                            style: TextStyle(fontSize: 26)),
                        onPressed: () =>
                            _showQuantityDialog(index, item.quantity),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 3, color: AppColors.brightText),
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: IconButton(
                          iconSize: 36,
                          icon: Icon(Icons.add, size: 36),
                          onPressed: () => widget.onTapAddToCart(index),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  void _showQuantityDialog(int index, int quantity) {
    showDialog(
      context: context,
      builder: (context) => QuantityDialog(
        quantity: quantity,
        onSuccess: (value) => widget.onChangeQuantityOfCartItem(index, value),
      ),
    );
  }
}
