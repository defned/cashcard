import 'package:cashcard/db/db.dart';

class CartItem {
  final DbRecordProduct product;
  int quantity;

  CartItem({this.product, this.quantity = 1});
}
