import 'package:flutter/material.dart';

class GenreFilterChips extends StatefulWidget {
  final Set<String> selectedGenres;
  final Function(Set<String>) onGenresChanged;

  GenreFilterChips({required this.selectedGenres, required this.onGenresChanged});

  @override
  _GenreFilterChipsState createState() => _GenreFilterChipsState();
}

class _GenreFilterChipsState extends State<GenreFilterChips> {
  late Set<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _selectedGenres = widget.selectedGenres;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genre'),
        Wrap(
          spacing: 8.0,
          children: _getFilterChips(),
        ),
      ],
    );
  }

  List<Widget> _getFilterChips() {
    return [
      'Futuristic',
      'School Life',
      'Fantasy',
      'Horror',
      'Historical (Western)',
      'Modern Day'
    ].map((filterOption) {
      final isSelected = _selectedGenres.contains(filterOption);
      return FilterChip(
        label: Text(filterOption),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            if (isSelected) {
              _selectedGenres.add(filterOption);
            } else {
              _selectedGenres.remove(filterOption);
            }
          });
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(GenreFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedGenres != widget.selectedGenres) {
      _selectedGenres = widget.selectedGenres;
      widget.onGenresChanged(_selectedGenres);
    }
  }

}