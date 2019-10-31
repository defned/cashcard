import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

class ModalDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Widget> actions;
  final Widget content;
  const ModalDialog(
      {this.icon,
      this.iconColor = Colors.black,
      this.content,
      this.actions,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // title: Text(AppLocalizations.of(context).title),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Icon(
          icon,
          size: 40,
          color: iconColor,
        ),
      ),
      content: content,
      actions: actions,
    );
  }
}

class WarningDialog extends ModalDialog {
  WarningDialog({List<Widget> actions, Widget content, Key key})
      : super(
            icon: MaterialIcons.getIconData('warning'),
            iconColor: Colors.red.shade600,
            content: content,
            actions: actions,
            key: key);
}

class QuestionDialog extends ModalDialog {
  QuestionDialog({List<Widget> actions, Widget content, Key key})
      : super(
            icon: MaterialIcons.getIconData('question'),
            content: content,
            actions: actions,
            key: key);
}
