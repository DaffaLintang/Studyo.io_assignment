import 'package:flutter/material.dart';

class AppContainer extends StatelessWidget {
  const AppContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.all(20.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFeba0f4), 
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Color(0xffae55ad),
                offset: Offset(6, 6),
              ),
            ],
          ),
          child: child
        );
  }
}