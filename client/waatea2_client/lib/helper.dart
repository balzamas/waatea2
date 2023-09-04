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

String returnLevelText(int level) {
  switch (level) {
    case 0:
      return "High performance, performance motivation";
    case 1:
      return "Basic performance, performance motivation";
    case 2:
      return "High performance, time deficit";

    case 3:
      return "High performance, social motivation";

    case 4:
      return "Basic performance, social motivation";

    case 5:
      return "Newcomer";
    default:
      return "None";
  }
}

String returnAbonnementText(int val) {
  switch (val) {
    case 0:
      return "Not set";
    case 1:
      return "None";
    case 2:
      return "Halbtax/Half fare";

    case 3:
      return "GA/AG";
    case 4:
      return "ZVV";
    default:
      return "Not Set";
  }
}
