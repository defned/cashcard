import 'package:cashcard/util/cart.dart';
import 'package:flutter/material.dart';

class Cart extends StatefulWidget {
  final Function(int) onTapRemoveFromCart;
  final Function(int) onTapAddToCart;
  final List<CartItem> cartItems;
  Cart({Key key, this.cartItems, this.onTapRemoveFromCart, this.onTapAddToCart})
      : super(key: key);
  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.cartItems.length,
        itemBuilder: (context, index) {
          var item = widget.cartItems[index];
          return ListTile(
            title: Text(item.product.name),
            subtitle: Text("${item.product.priceHuf} Ft",
                style: TextStyle(fontSize: 16)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () => widget.onTapRemoveFromCart(index),
                ),
                Text('${item.quantity}x', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => widget.onTapAddToCart(index),
                ),
              ],
            ),
          );
        });
  }
}
