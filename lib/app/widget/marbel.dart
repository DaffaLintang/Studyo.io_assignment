import 'package:flutter/material.dart';

class Marbel extends StatelessWidget {
  const Marbel({super.key, this.fill, this.border, this.isRectangle = false});

  final Color? fill;
  final Color? border;
  final bool isRectangle;

  @override
  Widget build(BuildContext context) {
    final Color fillColor = fill ?? const Color(0xff8355bf);
    final Color borderColor = border ?? const Color(0xff6c2e8e);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(isRectangle ? 8 : 50),
        border: Border.all(color: borderColor, width: 3),
      ),
    );
  }
}
