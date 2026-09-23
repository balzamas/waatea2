import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GameRow extends StatelessWidget {
  final String gameId;
  final String game;
  final String gameDate;
  final int dayofyear;
  final String season;
  final VoidCallback? onTap;

  const GameRow({
    super.key,
    required this.gameId,
    required this.game,
    required this.gameDate,
    required this.dayofyear,
    required this.season,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatterTime = DateFormat('HH:mm');
    final date = DateTime.parse(gameDate).toLocal();

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Container(
          color: const Color.fromARGB(255, 245, 245, 245),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$game // ${formatterTime.format(date)}',
                          style: DefaultTextStyle.of(
                            context,
                          ).style.apply(fontSizeFactor: 1.5),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.edit_outlined, color: Colors.black54),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day}.${date.month}.${date.year}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
