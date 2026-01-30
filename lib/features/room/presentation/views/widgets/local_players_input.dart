import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

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
    _initializeControllers(widget.maxPlayers);
  }

  @override
  void didUpdateWidget(LocalPlayersInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle maxPlayers change
    if (oldWidget.maxPlayers != widget.maxPlayers) {
      _handleMaxPlayersChange(oldWidget.maxPlayers, widget.maxPlayers);
    }
  }

  void _handleMaxPlayersChange(int oldMax, int newMax) {
    if (newMax > oldMax) {
      // Add more controllers
      for (int i = oldMax; i < newMax; i++) {
        final controller = TextEditingController();
        controller.addListener(() => _updatePlayerNames());
        _controllers.add(controller);
        _playerNames.add('');
      }
    } else if (newMax < oldMax) {
      // Remove extra controllers
      for (int i = oldMax - 1; i >= newMax; i--) {
        _controllers[i].dispose();
        _controllers.removeAt(i);
        _playerNames.removeAt(i);
      }
    }
    // Defer the callback to after the build phase
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        _notifyPlayersChanged();
      }
    });
  }

  void _initializeControllers(int count) {
    // Clear existing controllers first
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    _playerNames.clear();

    for (int i = 0; i < count; i++) {
      final controller = TextEditingController();
      controller.addListener(() => _updatePlayerNames());
      _controllers.add(controller);
      _playerNames.add('');
    }
  }

  void _updatePlayerNames() {
    setState(() {
      for (int i = 0; i < _controllers.length; i++) {
        _playerNames[i] = _controllers[i].text.trim();
      }
    });
    _notifyPlayersChanged();
  }

  void _notifyPlayersChanged() {
    final names = _controllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.users,
                color: AppColors.primary,
                size: isTablet ? 24 : 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enter Player Names',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
            style: TextStyle(
              color: AppColors.textSecondary,
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
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: 'Enter name...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: _playerNames[index].isEmpty
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      size: 18,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At least 2 players required to start the game',
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
