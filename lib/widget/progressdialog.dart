import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/material.dart';

class ProgressDialog extends StatefulWidget {
  final double progress;
  final int maxCount;
  ProgressDialog({Key key, this.progress, this.maxCount}) : super(key: key);
  @override
  ProgressDialogState createState() => ProgressDialogState();
}

class ProgressDialogState extends State<ProgressDialog>
    with StateWithLocalization<ProgressDialog> {
  ValueNotifier progress = ValueNotifier<double>(0);

  void refresh() {
    setState(() {});
  }

  @override
  void initState() {
    progress = ValueNotifier<double>(widget.progress);
    progress.addListener(refresh);
    super.initState();
  }

  @override
  void dispose() {
    progress.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
              child: Text(tr('progress'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          SizedBox(height: 20),
          if (progress.value == 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.check,
                  size: 40,
                  color: Colors.green.shade600,
                ),
                SizedBox(width: 10),
                Text(
                  "${tr('importAction')} ${tr('succeeded')} (${widget.maxCount} / ${widget.maxCount})",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          Flexible(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress.value,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "${(progress.value * 100).ceil()}%",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
              ],
            ),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              MaterialButton(
                child: Text(tr('close')),
                onPressed: progress.value == 1
                    ? () {
                        Navigator.maybePop(context);
                      }
                    : null,
              )
            ],
          ),
        ],
      ),
    );
  }
}
