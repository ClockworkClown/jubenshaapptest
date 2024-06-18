import 'package:flutter/material.dart';

class ContentWarningFilterChips extends StatefulWidget {
  final Set<String> selectedContentWarnings;
  final Function(Set<String>) onContentWarningsChanged;

  ContentWarningFilterChips({required this.selectedContentWarnings, required this.onContentWarningsChanged});

  @override
  _ContentWarningFilterChipsState createState() => _ContentWarningFilterChipsState();
}

class _ContentWarningFilterChipsState extends State<ContentWarningFilterChips> {
  late Set<String> _selectedContentWarnings;

  @override
  void initState() {
    super.initState();
    _selectedContentWarnings = widget.selectedContentWarnings;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Content Warnings (This filters out the ones you select):'),
        Wrap(
          spacing: 8.0,
          children: _getFilterChips(),
        ),
      ],
    );
  }

  List<Widget> _getFilterChips() {
    return [
      'sexual assault',
      'heavy gore',
      'frightening themes',
      'suicidal thoughts',
      'heavy bullying'
    ].map((filterOption) {
      final isSelected = _selectedContentWarnings.contains(filterOption);
      return FilterChip(
        label: Text(filterOption),
        selected: isSelected,
        onSelected: (isSelected) {
          setState(() {
            if (isSelected) {
              _selectedContentWarnings.add(filterOption);
            } else {
              _selectedContentWarnings.remove(filterOption);
            }
          });
        },
      );
    }).toList();
  }

  @override
  void didUpdateWidget(ContentWarningFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedContentWarnings != widget.selectedContentWarnings) {
      _selectedContentWarnings = widget.selectedContentWarnings;
      widget.onContentWarningsChanged(_selectedContentWarnings);
    }
  }
}