import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart' as globals;

class SetAttendanceRow extends StatefulWidget {
  /// e.g. "Mon, 8 Sep 2025 – 20:15"
  final String whenLabel;

  /// e.g. "08.09.2025"
  final String dateLabel;

  /// 0 unset, 1 yes, 2 no
  final int initialState;

  /// may be "" if none yet
  final String initialAttendanceId;

  final String trainingId;
  final int dayofyear;
  final String season;

  const SetAttendanceRow({
    Key? key,
    required this.whenLabel,
    required this.dateLabel,
    required this.initialState,
    required this.initialAttendanceId,
    required this.trainingId,
    required this.dayofyear,
    required this.season,
  }) : super(key: key);

  @override
  State<SetAttendanceRow> createState() => _SetAttendanceRowState();
}

class _SetAttendanceRowState extends State<SetAttendanceRow> {
  late int _state; // 0 unset, 1 yes, 2 no
  late String _attendancePk; // "" if none yet
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _attendancePk = widget.initialAttendanceId;
  }

  Future<void> _save(int nextState) async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _state = nextState; // optimistic
    });

    final headers = {
      'Authorization': 'Token ${globals.token}',
      'Content-Type': 'application/json; charset=UTF-8',
    };

    try {
      if (_attendancePk.isNotEmpty) {
        // PATCH existing
        final resp = await http.patch(
          Uri.parse('${globals.URL_PREFIX}/api/attendance/${_attendancePk}/'),
          headers: headers,
          body: jsonEncode({'attended': nextState == 1}),
        );
        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          throw Exception('PATCH ${resp.statusCode}');
        }
      } else {
        // POST new
        final body = {
          'attended': nextState == 1,
          'dayofyear': widget.dayofyear,
          'player': globals.playerId,
          'training': widget.trainingId,
          'season': widget.season,
        };
        final resp = await http.post(
          Uri.parse('${globals.URL_PREFIX}/api/attendance/'),
          headers: headers,
          body: jsonEncode(body),
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final data = jsonDecode(resp.body);
          _attendancePk = data['pk']?.toString() ?? '';
        } else {
          throw Exception('POST ${resp.statusCode}');
        }
      }
    } catch (e) {
      // revert UI on failure
      if (mounted) {
        setState(() {
          _state = widget.initialState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save attendance: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yesSelected = _state == 1;
    final noSelected = _state == 2;

    final leadingIcon = _state == 1
        ? const Icon(Icons.check_circle, color: Colors.green)
        : _state == 2
            ? const Icon(Icons.cancel, color: Colors.red)
            : const Icon(Icons.help_outline, color: Colors.orange);

    return ListTile(
      leading: leadingIcon,
      title: Text(widget.dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(widget.whenLabel),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'I will attend',
            onPressed: _saving ? null : () => _save(1),
            icon: yesSelected
                ? const Icon(Icons.check_circle, size: 28)
                : const Icon(Icons.check_circle_outline, size: 28),
            color: yesSelected ? Colors.green : null,
          ),
          IconButton(
            tooltip: "I can't attend",
            onPressed: _saving ? null : () => _save(2),
            icon: noSelected
                ? const Icon(Icons.cancel, size: 28)
                : const Icon(Icons.cancel_outlined, size: 28),
            color: noSelected ? Colors.red : null,
          ),
        ],
      ),
    );
  }
}
