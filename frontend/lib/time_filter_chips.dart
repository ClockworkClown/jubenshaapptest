import 'package:flutter/material.dart';

class TimeFilterChips extends StatefulWidget {
  final Set<Duration> selectedTimes;
  final Function(Set<Duration>) onTimesChanged;

  TimeFilterChips({required this.selectedTimes, required this.onTimesChanged});

  @override
  _TimeFilterChipsState createState() => _TimeFilterChipsState();
}

class _TimeFilterChipsState extends State<TimeFilterChips> {
  late Set<Duration> _selectedTimes;
  late List<Duration> _timeOptions;

  @override
  void initState() {
    super.initState();
    _selectedTimes = widget.selectedTimes;
    _generateTimeOptions();
  }

  void _generateTimeOptions() {
    _timeOptions = [];
    for (int i = 30; i <= 240; i += 30) {
      _timeOptions.add(Duration(minutes: i));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time'),
        Wrap(
          spacing: 8.0,
          children: _getFilterChips(),
        ),
      ],
    );
  }

  List<Widget> _getFilterChips() {
    return _timeOptions.map((duration) {
      final isSelected = _selectedTimes.contains(duration);
      return FilterChip(
        label: Text('${duration.inHours}h ${(duration.inMinutes % 60)}m'),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            if (isSelected) {
              _selectedTimes.add(duration);
            } else {
              _selectedTimes.remove(duration);
            }
          });
          widget.onTimesChanged(_selectedTimes);
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(TimeFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedTimes != widget.selectedTimes) {
      _selectedTimes = widget.selectedTimes;
    }
  }
}