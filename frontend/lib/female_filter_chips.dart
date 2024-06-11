import 'package:flutter/material.dart';

class FemalePlayersFilterChips extends StatefulWidget {
  final Set<int> selectedFemalePlayers;
  final Function(Set<int>) onFemalePlayersChanged;

  FemalePlayersFilterChips({required this.selectedFemalePlayers, required this.onFemalePlayersChanged});

  @override
  _FemalePlayersFilterChipsState createState() => _FemalePlayersFilterChipsState();
}

class _FemalePlayersFilterChipsState extends State<FemalePlayersFilterChips> {
  late Set<int> _selectedFemalePlayers;

  @override
  void initState() {
    super.initState();
    _selectedFemalePlayers = widget.selectedFemalePlayers;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Female Players'),
        Wrap(
          spacing: 8.0,
          children: _getFilterChips(),
        ),
      ],
    );
  }

  List<Widget> _getFilterChips() {
    return List.generate(9, (index) => index + 2).map((players) {
      final isSelected = _selectedFemalePlayers.contains(players);
      return FilterChip(
        label: Text(players.toString()),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            if (isSelected) {
              _selectedFemalePlayers.add(players);
            } else {
              _selectedFemalePlayers.remove(players);
            }
          });
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(FemalePlayersFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedFemalePlayers != widget.selectedFemalePlayers) {
      _selectedFemalePlayers = widget.selectedFemalePlayers;
      widget.onFemalePlayersChanged(_selectedFemalePlayers);
    }
  }
}