import 'package:cashcard/util/extensions.dart';
import 'package:flutter/material.dart';

class ProgressDialog extends StatefulWidget {
  final double progress;
  final int maxCount;
  const ProgressDialog(
      {super.key, required this.progress, required this.maxCount});
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
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          if (progress.value == 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.check,
                  size: 40,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 10),
                Text(
                  "${tr('importAction')} ${tr('succeeded')} (${widget.maxCount} / ${widget.maxCount})",
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.bold),
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
                const SizedBox(width: 10),
                Text(
                  "${(progress.value * 100).ceil()}%",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                )
              ],
            ),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              MaterialButton(
                onPressed: progress.value == 1
                    ? () {
                        Navigator.maybePop(context);
                      }
                    : null,
                child: Text(tr('close')),
              )
            ],
          ),
        ],
      ),
    );
  }
}
