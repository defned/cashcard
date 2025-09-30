import 'package:cashcard/app/style.dart';
import 'package:flutter/material.dart';

class HunVirtualKeyboard extends StatefulWidget {
  static String shiftKeyChar = "⇧";
  static String spaceKeyChar = "␣";
  static String backspaceKeyChar = "⌫";

  final Function(String key) onKeyTap;
  HunVirtualKeyboard({Key key, this.onKeyTap}) : super(key: key);
  @override
  _HunVirtualKeyboardState createState() => _HunVirtualKeyboardState();
}

class _HunVirtualKeyboardState extends State<HunVirtualKeyboard> {
  bool isShiftToggled = false;
  List<List<String>> keysSets = [
    [
      "0",
      "1",
      "2",
      "3",
      "4",
      "5",
      "6",
      "7",
      "8",
      "9",
      "ö",
      "ü",
      "ó",
      HunVirtualKeyboard.backspaceKeyChar
    ],
    ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p", "ő", "ú"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", "é", "á", "ű"],
    [
      HunVirtualKeyboard.shiftKeyChar,
      "í",
      "y",
      "x",
      "c",
      "v",
      "b",
      "n",
      "m",
      "-",
      "_",
      HunVirtualKeyboard.shiftKeyChar
    ],
    [HunVirtualKeyboard.spaceKeyChar],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: keysSets
          .map((keys) =>
              Row(children: keys.map((k) => _buildCap(k, false)).toList()))
          .toList(),
    );
  }

  Widget _buildCap(String keyText, bool shift) {
    Color fillColor =
        isShiftToggled == true && keyText == HunVirtualKeyboard.shiftKeyChar
            ? Colors.grey.shade700
            : null;
    return Expanded(
      child: Container(
        height: 70,
        child: RawMaterialButton(
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 3, color: AppColors.brightText),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(isShiftToggled ? keyText.toUpperCase() : keyText,
                style: TextStyle(fontSize: 32)),
          ),
          fillColor: fillColor,
          onPressed: () {
            String key = isShiftToggled ? keyText.toUpperCase() : keyText;
            if (keyText == HunVirtualKeyboard.shiftKeyChar) {
              setState(() {
                isShiftToggled = !isShiftToggled;
              });
            }
            if (widget.onKeyTap != null) {
              widget.onKeyTap(key);
            }
          },
        ),
      ),
    );
  }
}
