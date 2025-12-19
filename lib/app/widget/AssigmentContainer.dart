import 'package:flutter/widgets.dart';

class Assigment extends StatelessWidget {
  const Assigment({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 150,
          width: MediaQuery.of(context).size.width / 1.3,
          decoration: BoxDecoration(
            color: Color(0xFF7e4db8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Color(0xFF5a1d8c), offset: Offset(8, 8)),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xffd4befd),
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          height: 50,
          width: 100,
          decoration: BoxDecoration(
            color: Color(0xFF561f96),
            boxShadow: [
              BoxShadow(color: Color(0xFF31025f), offset: Offset(6, 6)),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              "=",
              style: TextStyle(
                color: Color(0xffd4befd),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
