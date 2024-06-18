import 'package:flutter/material.dart';

class FeaturedFilterChips extends StatefulWidget {
  final Set<bool> selectedFeatured;
  final Function(Set<bool>) onFeaturedChanged;

  FeaturedFilterChips({required this.selectedFeatured, required this.onFeaturedChanged});

  @override
  _FeaturedFilterChipsState createState() => _FeaturedFilterChipsState();
}

class _FeaturedFilterChipsState extends State<FeaturedFilterChips> {
  late Set<bool> _selectedFeatured;

  @override
  void initState() {
    super.initState();
    _selectedFeatured = Set.from(widget.selectedFeatured);
  }

  void _handleChipTapped(bool value) {
    setState(() {
      if (_selectedFeatured.contains(value)) {
        _selectedFeatured.remove(value);
      } else {
        _selectedFeatured.add(value);
      }
      widget.onFeaturedChanged(_selectedFeatured);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured:',
        ),
        Wrap(
          spacing: 8.0,
          children: [
            ChoiceChip(
              label: Text('Featured'),
              selected: _selectedFeatured.contains(true),
              onSelected: (selected) {
                _handleChipTapped(true);
              },
            ),
            ChoiceChip(
              label: Text('Not Featured'),
              selected: _selectedFeatured.contains(false),
              onSelected: (selected) {
                _handleChipTapped(false);
              },
            ),
          ],
        ),
      ],
    );
  }
}