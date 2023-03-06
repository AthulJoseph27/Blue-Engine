import 'package:flutter/cupertino.dart';

class CupertinoRow extends StatelessWidget {
  final Widget firstChild, secondChild;
  final double spacingRatio;
  const CupertinoRow(
      {Key? key, required this.firstChild, required this.secondChild, this.spacingRatio = 1.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / 2.0 * spacingRatio - 8;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: width,
            child: Row(
              children: [
                const Spacer(),
                firstChild,
              ],
            ),
          ),
          secondChild,
        ],
      ),
    );
  }
}
