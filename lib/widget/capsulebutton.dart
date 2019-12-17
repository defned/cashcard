import 'package:flutter/material.dart';

class BottomCapsuleButton extends StatelessWidget {
  final Color color;
  final Function onTap;
  final String text;
  const BottomCapsuleButton({Key key, this.color, this.onTap, this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
            minimum: EdgeInsets.only(bottom: 16),
            child: CapsuleButton(
                color: color,
                onTap: onTap,
                child: Text(text.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)))));
  }
}

class CapsuleButton extends StatelessWidget {
  final Color color;
  final Function onTap;
  final Widget child;
  final double borderRadiusSize;
  final double horizontalPadding;
  final double height;

  CapsuleButton(
      {this.color,
      this.onTap,
      this.child,
      this.horizontalPadding = 20,
      this.height = 50,
      this.borderRadiusSize = 40});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          // shape: shape,
          borderRadius: BorderRadius.circular(borderRadiusSize),
          color: color,
          // boxShadow: [
          //   BoxShadow(
          //       color: color.withOpacity(0.4),
          //       spreadRadius: 0.0,
          //       blurRadius: 5.0,
          //       offset: Offset(0.0, 7.0)),
          // ],
        ),
        child: Material(
          // type: MaterialType.transparency,
          // color: Colors.transparent,
          color: color,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSize)),
          child: InkWell(
            // splashColor: _darker2,
            // highlightColor: _darker1,
            onTap: onTap,
            child: Center(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
