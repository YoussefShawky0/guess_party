import 'package:flutter/material.dart';

class LocalPlayersInput extends StatefulWidget {
  final int maxPlayers;
  final ValueChanged<List<String>> onPlayersChanged;

  const LocalPlayersInput({
    super.key,
    required this.maxPlayers,
    required this.onPlayersChanged,
  });

  @override
  State<LocalPlayersInput> createState() => _LocalPlayersInputState();
}

class _LocalPlayersInputState extends State<LocalPlayersInput> {
  final List<TextEditingController> _controllers = [];
  final List<String> _playerNames = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < widget.maxPlayers; i++) {
      final controller = TextEditingController();
      controller.addListener(() => _updatePlayerNames());
      _controllers.add(controller);
      _playerNames.add('');
    }
  }

  void _updatePlayerNames() {
    final names = _controllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    setState(() {
      for (int i = 0; i < _controllers.length; i++) {
        _playerNames[i] = _controllers[i].text.trim();
      }
    });
    widget.onPlayersChanged(names);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: theme.colorScheme.primary,
                size: isTablet ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enter Player Names',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 22 : 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter names for players who will play on this device',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            widget.maxPlayers,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[index],
                decoration: InputDecoration(
                  labelText: 'Player ${index + 1}',
                  hintText: 'Enter name...',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: _playerNames[index].isEmpty
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At least 2 players required to start the game',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
