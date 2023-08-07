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

Icon returnLevelIcon(int level) {
  switch (level) {
    case 0:
      return const Icon(
        Icons.star,
        color: Colors.black,
      );
    case 1:
      return const Icon(
        Icons.star_border,
        color: Colors.black,
      );
    case 2:
      return const Icon(
        Icons.lock_clock,
        color: Colors.black,
      );
    case 3:
      return const Icon(
        Icons.local_bar,
        color: Colors.black,
      );
    case 4:
      return const Icon(
        Icons.liquor,
        color: Colors.black,
      );
    case 5:
      return const Icon(
        Icons.pets,
        color: Colors.black,
      );
    default:
      return const Icon(
        Icons.error,
        color: Colors.red,
      );
  }
}
