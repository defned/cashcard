import 'package:flutter/material.dart';

class SubPage extends StatelessWidget {
  final String title;
  final Widget child;
  final Function onPop;
  SubPage({Key key, this.title, this.child, this.onPop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (onPop != null) onPop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: child,
    );
  }
}
