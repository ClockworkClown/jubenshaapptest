import 'package:flutter/material.dart';

class TotalPlayersFilterChips extends StatefulWidget {
  final Set<int> selectedTotalPlayers;
  final Function(Set<int>) onTotalPlayersChanged;

  TotalPlayersFilterChips({required this.selectedTotalPlayers, required this.onTotalPlayersChanged});

  @override
  _TotalPlayersFilterChipsState createState() => _TotalPlayersFilterChipsState();
}

class _TotalPlayersFilterChipsState extends State<TotalPlayersFilterChips> {
  late Set<int> _selectedTotalPlayers;

  @override
  void initState() {
    super.initState();
    _selectedTotalPlayers = widget.selectedTotalPlayers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Players'),
        Wrap(
          spacing: 8.0,
          children: _getFilterChips(),
        ),
      ],
    );
  }

  List<Widget> _getFilterChips() {
    return List.generate(9, (index) => index + 2).map((players) {
      final isSelected = _selectedTotalPlayers.contains(players);
      return FilterChip(
        label: Text(players.toString()),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            if (isSelected) {
              _selectedTotalPlayers.add(players);
            } else {
              _selectedTotalPlayers.remove(players);
            }
          });
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(TotalPlayersFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedTotalPlayers != widget.selectedTotalPlayers) {
      _selectedTotalPlayers = widget.selectedTotalPlayers;
      widget.onTotalPlayersChanged(_selectedTotalPlayers);
    }
  }

}
