import 'package:flutter/material.dart';

class MalePlayersFilterChips extends StatefulWidget {
  final Set<int> selectedMalePlayers;
  final Function(Set<int>) onMalePlayersChanged;

  MalePlayersFilterChips({required this.selectedMalePlayers, required this.onMalePlayersChanged});

  @override
  _MalePlayersFilterChipsState createState() => _MalePlayersFilterChipsState();
}

class _MalePlayersFilterChipsState extends State<MalePlayersFilterChips> {
  late Set<int> _selectedMalePlayers;

  @override
  void initState() {
    super.initState();
    _selectedMalePlayers = widget.selectedMalePlayers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Male Players'),
        Wrap(
          spacing: 8.0,
          children: _getFilterChips(),
        ),
      ],
    );
  }

  List<Widget> _getFilterChips() {
    return List.generate(9, (index) => index + 2).map((players) {
      final isSelected = _selectedMalePlayers.contains(players);
      return FilterChip(
        label: Text(players.toString()),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            if (isSelected) {
              _selectedMalePlayers.add(players);
            } else {
              _selectedMalePlayers.remove(players);
            }
          });
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(MalePlayersFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedMalePlayers != widget.selectedMalePlayers) {
      _selectedMalePlayers = widget.selectedMalePlayers;
      widget.onMalePlayersChanged(_selectedMalePlayers);
    }
  }

}