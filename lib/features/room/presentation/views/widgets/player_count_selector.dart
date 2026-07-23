import 'package:flutter/material.dart';

import 'custom_player_count_option.dart';
import 'max_players_selector.dart';

export 'custom_player_count_option.dart';

class PlayerCountSelector extends StatefulWidget {
  const PlayerCountSelector({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final int initialValue;
  final ValueChanged<int?> onChanged;

  @override
  State<PlayerCountSelector> createState() => _PlayerCountSelectorState();
}

class _PlayerCountSelectorState extends State<PlayerCountSelector> {
  int? _selectedPreset;
  bool _isCustomSelected = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialValue;
  }

  void _selectPreset(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedPreset = value;
      _isCustomSelected = false;
    });
    widget.onChanged(value);
  }

  void _selectCustom(int? value) {
    setState(() {
      _selectedPreset = null;
      _isCustomSelected = true;
    });
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaxPlayersSelector(
      selectedMaxPlayers: _selectedPreset,
      onMaxPlayersChanged: _selectPreset,
      trailingOption: CustomPlayerCountOption(
        isSelected: _isCustomSelected,
        onSelected: _selectCustom,
      ),
    );
  }
}
