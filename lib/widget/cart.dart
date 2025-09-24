import 'package:cashcard/app/style.dart';
import 'package:cashcard/util/cart.dart';
import 'package:flutter/material.dart';

class Cart extends StatefulWidget {
  final Function(int) onTapRemoveFromCart;
  final Function(int) onTapAddToCart;
  final ValueNotifier<int> itemsChanged;
  final List<CartItem> cartItems;
  Cart(
      {Key key,
      this.cartItems,
      this.onTapRemoveFromCart,
      this.onTapAddToCart,
      this.itemsChanged})
      : super(key: key);
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
                      const SizedBox(width: 20),
                      Text('${item.quantity}x', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 20),
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
}
