import 'package:cashcard/util/extensions.dart';
import 'package:flutter/material.dart';

class SubPage extends StatefulWidget {
  final String title;
  final Widget? child;
  final Function()? onPop;
  final List<Widget>? actions;
  SubPage(
      {super.key, required this.title, this.child, this.onPop, this.actions});

  @override
  _SubPageState createState() => _SubPageState();
}

class _SubPageState extends State<SubPage> with StateWithLocalization<SubPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 20),
        ),
        leading: IconButton(
          tooltip: tr('back'),
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            widget.onPop?.call();
            Navigator.of(context).pop();
          },
        ),
        actions: widget.actions,
      ),
      body: widget.child,
    );
  }
}
