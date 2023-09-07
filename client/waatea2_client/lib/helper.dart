import 'package:flutter/material.dart';

Icon returnStateIcon(int state) {
  switch (state) {
    case 1:
      return const Icon(
        Icons.thumb_down_alt_outlined,
        color: Colors.red,
      );
    case 2:
      return const Icon(
        Icons.help_outline,
        color: Colors.orange,
      );
    case 3:
      return const Icon(
        Icons.thumb_up_alt_outlined,
        color: Colors.green,
      );
    default:
      return const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
      );
  }
}
