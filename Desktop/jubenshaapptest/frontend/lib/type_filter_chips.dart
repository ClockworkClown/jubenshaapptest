import 'package:flutter/material.dart';

class TypeFilterChips extends StatefulWidget {
  final Set<String> selectedTypes;
  final Function(Set<String>) onTypesChanged;

  TypeFilterChips({required this.selectedTypes, required this.onTypesChanged});

  @override
  _TypeFilterChipsState createState() => _TypeFilterChipsState();
}

class _TypeFilterChipsState extends State<TypeFilterChips> {
  late Set<String> _selectedTypes;

  @override
  void initState() {
    super.initState();
    _selectedTypes = widget.selectedTypes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type'),
        Wrap(
          spacing: 8.0,
          children: _getFilterChips(),
        ),
      ],
    );
  }

  List<Widget> _getFilterChips() {
    return [
      'Balanced',
      'Emotional',
      'Reasoning Focused',
      'Roleplay Focused',
      'Team Based',
      'Lighthearted'
    ].map((filterOption) {
      final isSelected = _selectedTypes.contains(filterOption);
      return ChoiceChip(
        label: Text(filterOption),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            if (isSelected) {
              _selectedTypes.add(filterOption);
            } else {
              _selectedTypes.remove(filterOption);
            }
          });
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(TypeFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedTypes != widget.selectedTypes) {
      _selectedTypes = widget.selectedTypes;
      widget.onTypesChanged(_selectedTypes);
    }
  }

}