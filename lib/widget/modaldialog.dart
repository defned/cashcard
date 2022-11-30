import 'package:flutter/material.dart';

class ModalDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Widget>? actions;
  final Widget? content;
  const ModalDialog(
      {super.key,
      required this.icon,
      this.content,
      this.iconColor = Colors.black,
      this.actions});

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
  WarningDialog({super.key, List<Widget>? actions, Widget? content})
      : super(
            icon: Icons.warning,
            iconColor: Colors.red.shade600,
            content: content,
            actions: actions);
}

class QuestionDialog extends ModalDialog {
  const QuestionDialog({super.key, List<Widget>? actions, Widget? content})
      : super(icon: Icons.question_answer, content: content, actions: actions);
}
