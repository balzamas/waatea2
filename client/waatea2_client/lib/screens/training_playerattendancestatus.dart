import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../globals.dart' as globals;
import '../models/attendance.dart';
import '../models/user_model.dart';

enum AttendanceFilter { attending, absent, noStatus, all }

class PlayerAttendanceStatusScreen extends StatefulWidget {
  final String trainingId;

  const PlayerAttendanceStatusScreen({super.key, required this.trainingId});

  @override
  State<PlayerAttendanceStatusScreen> createState() =>
      _PlayerAttendanceStatusScreenState();
}

class _PlayerAttendanceStatusScreenState
    extends State<PlayerAttendanceStatusScreen> {
  List<UserModel> players = [];

  // playerId -> attended
  // true = attending
  // false = absent
  // missing = no status
  final Map<String, bool> attendanceMap = {};

  // playerId -> attendance record id
  final Map<String, String> attendanceIdByPlayer = {};

  bool _loading = false;

  AttendanceFilter _filter = AttendanceFilter.attending;

  @override
  void initState() {
    super.initState();
    fetchPlayersAndAttendance();
  }

  Future<void> fetchPlayersAndAttendance() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final responsePlayers = await http.get(
        Uri.parse(
          '${globals.URL_PREFIX}/api/users/filter'
          '?club=${globals.clubId}',
        ),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (responsePlayers.statusCode != 200) {
        debugPrint(
          'Error loading players: '
          '${responsePlayers.statusCode} '
          '${responsePlayers.body}',
        );
        return;
      }

      final playersData =
          json.decode(utf8.decode(responsePlayers.bodyBytes)) as List;

      //
      // Only active players.
      //
      final loadedPlayers =
          playersData
              .map((json) => UserModel.fromJson(json))
              .where((player) => player.profile.isPlaying)
              .toList();

      final responseAttendance = await http.get(
        Uri.parse(
          '${globals.URL_PREFIX}/api/attendances/filter'
          '?training=${widget.trainingId}'
          '&season=${globals.seasonID}',
        ),
        headers: {'Authorization': 'Token ${globals.token}'},
      );

      if (responseAttendance.statusCode != 200) {
        debugPrint(
          'Error loading attendance: '
          '${responseAttendance.statusCode} '
          '${responseAttendance.body}',
        );
        return;
      }

      final attendanceData =
          json.decode(utf8.decode(responseAttendance.bodyBytes)) as List;

      final List<AttendanceModel> attendances =
          attendanceData.map((json) => AttendanceModel.fromJson(json)).toList();

      attendanceMap.clear();
      attendanceIdByPlayer.clear();

      for (final attendance in attendances) {
        final playerId = attendance.player.toString();

        attendanceMap[playerId] = attendance.attended;

        final attendanceId = attendance.pk.toString();

        if (attendanceId.isNotEmpty) {
          attendanceIdByPlayer[playerId] = attendanceId;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        players = loadedPlayers;
      });
    } catch (e) {
      debugPrint('Error loading players and attendance: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int _todayDayOfYear() {
    final now = DateTime.now();

    return now.difference(DateTime(now.year)).inDays + 1;
  }

  bool? _attendanceFor(UserModel player) {
    return attendanceMap[player.pk.toString()];
  }

  int _statusOrder(UserModel player) {
    final attended = _attendanceFor(player);

    if (attended == true) {
      return 0;
    }

    if (attended == false) {
      return 1;
    }

    return 2;
  }

  List<UserModel> get _filteredPlayers {
    final filtered =
        players.where((player) {
          final attended = _attendanceFor(player);

          switch (_filter) {
            case AttendanceFilter.attending:
              return attended == true;

            case AttendanceFilter.absent:
              return attended == false;

            case AttendanceFilter.noStatus:
              return attended == null;

            case AttendanceFilter.all:
              return true;
          }
        }).toList();

    filtered.sort((a, b) {
      //
      // In "All", group by attendance status first.
      //
      if (_filter == AttendanceFilter.all) {
        final statusComparison = _statusOrder(a).compareTo(_statusOrder(b));

        if (statusComparison != 0) {
          return statusComparison;
        }
      }

      //
      // Alphabetical within each group.
      //
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  int get _attendingCount {
    return players.where((player) => _attendanceFor(player) == true).length;
  }

  int get _absentCount {
    return players.where((player) => _attendanceFor(player) == false).length;
  }

  int get _noStatusCount {
    return players.where((player) => _attendanceFor(player) == null).length;
  }

  Future<void> _setAttendance(UserModel player, bool attended) async {
    try {
      final playerId = player.pk.toString();

      final existingAttendanceId = attendanceIdByPlayer[playerId];

      final Map<String, dynamic> body = {
        'attended': attended,
        'dayofyear': _todayDayOfYear(),
        'player': player.pk,
        'training': widget.trainingId,
        'season': globals.seasonID,
      };

      late http.Response response;

      if (existingAttendanceId != null && existingAttendanceId.isNotEmpty) {
        response = await http.patch(
          Uri.parse(
            '${globals.URL_PREFIX}'
            '/api/attendance/$existingAttendanceId/',
          ),
          headers: {
            'Authorization': 'Token ${globals.token}',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(body),
        );

        if (response.statusCode >= 400) {
          response = await http.put(
            Uri.parse(
              '${globals.URL_PREFIX}'
              '/api/attendance/$existingAttendanceId/',
            ),
            headers: {
              'Authorization': 'Token ${globals.token}',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(body),
          );
        }
      } else {
        response = await http.post(
          Uri.parse('${globals.URL_PREFIX}/api/attendance/'),
          headers: {
            'Authorization': 'Token ${globals.token}',
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(body),
        );
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        await fetchPlayersAndAttendance();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attended
                  ? '${player.name} set to attending.'
                  : '${player.name} set to absent.',
            ),
          ),
        );

        return;
      }

      debugPrint(
        'Error updating attendance: '
        '${response.statusCode} ${response.body}',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update attendance '
            '(${response.statusCode}).',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error updating attendance: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while updating attendance.')),
      );
    }
  }

  Widget _buildStatusIcon(bool? attended) {
    if (attended == true) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 28);
    }

    if (attended == false) {
      return const Icon(Icons.cancel, color: Colors.red, size: 28);
    }

    return const Icon(Icons.help_outline, color: Colors.grey, size: 28);
  }

  String _statusLabel(bool? attended) {
    if (attended == true) {
      return 'Attending';
    }

    if (attended == false) {
      return 'Absent';
    }

    return 'No status';
  }

  Widget _buildAttendanceActions(UserModel player, bool? attended) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Attending',
          icon: Icon(
            attended == true ? Icons.check_circle : Icons.check_circle_outline,
            color: Colors.green,
          ),
          onPressed:
              attended == true
                  ? null
                  : () {
                    _setAttendance(player, true);
                  },
        ),
        IconButton(
          tooltip: 'Absent',
          icon: Icon(
            attended == false ? Icons.cancel : Icons.cancel_outlined,
            color: Colors.red,
          ),
          onPressed:
              attended == false
                  ? null
                  : () {
                    _setAttendance(player, false);
                  },
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('Show:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<AttendanceFilter>(
              initialValue: _filter,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: AttendanceFilter.attending,
                  child: Text('✓ Attending ($_attendingCount)'),
                ),
                DropdownMenuItem(
                  value: AttendanceFilter.absent,
                  child: Text('✕ Absent ($_absentCount)'),
                ),
                DropdownMenuItem(
                  value: AttendanceFilter.noStatus,
                  child: Text('? No status ($_noStatusCount)'),
                ),
                DropdownMenuItem(
                  value: AttendanceFilter.all,
                  child: Text('All (${players.length})'),
                ),
              ],
              onChanged: (AttendanceFilter? value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _filter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(UserModel player) {
    final attended = _attendanceFor(player);

    return ListTile(
      leading: _buildStatusIcon(attended),
      title: Text(player.name),
      subtitle: Text(_statusLabel(attended)),
      trailing: _buildAttendanceActions(player, attended),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = _filteredPlayers;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Status',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : fetchPlayersAndAttendance,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildFilterBar(),
                  const Divider(height: 1),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchPlayersAndAttendance,
                      child:
                          filteredPlayers.isEmpty
                              ? ListView(
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: Center(child: Text(_emptyMessage())),
                                  ),
                                ],
                              )
                              : ListView.separated(
                                itemCount: filteredPlayers.length,
                                separatorBuilder:
                                    (context, index) =>
                                        const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  return _buildPlayerRow(
                                    filteredPlayers[index],
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case AttendanceFilter.attending:
        return 'No players attending.';

      case AttendanceFilter.absent:
        return 'No absent players.';

      case AttendanceFilter.noStatus:
        return 'Everyone has set their status.';

      case AttendanceFilter.all:
        return 'No active players found.';
    }
  }
}
