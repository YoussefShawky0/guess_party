import 'package:flutter/material.dart';

class PassDeviceScreen extends StatefulWidget {
  final String playerName;
  final String? characterName;
  final bool isImpostor;
  final VoidCallback onRevealed;

  const PassDeviceScreen({
    super.key,
    required this.playerName,
    this.characterName,
    required this.isImpostor,
    required this.onRevealed,
  });

  @override
  State<PassDeviceScreen> createState() => _PassDeviceScreenState();
}

class _PassDeviceScreenState extends State<PassDeviceScreen>
    with SingleTickerProviderStateMixin {
  bool _isRevealed = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _revealCharacter() {
    setState(() => _isRevealed = true);
    _animationController.forward();
  }

  void _continue() {
    widget.onRevealed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (!_isRevealed) {
      return _buildPassDeviceView(theme, size, isTablet);
    }
    return _buildRevealedView(theme, size, isTablet);
  }

  Widget _buildPassDeviceView(
    ThemeData theme,
    Size size,
    bool isTablet,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? size.width * 0.15 : 32,
              vertical: 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  size: isTablet ? 120 : 100,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 40),
                Text(
                  'Pass device to',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isTablet ? 28 : 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.playerName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 56 : 48,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                Icon(
                  Icons.swipe_up_rounded,
                  size: isTablet ? 60 : 48,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to see your role',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: isTablet ? 24 : 20,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        color: theme.colorScheme.error,
                        size: isTablet ? 24 : 20,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          "Don't let others see!",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _revealCharacter,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 60 : 48,
                      vertical: isTablet ? 24 : 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Reveal Role',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevealedView(
    ThemeData theme,
    Size size,
    bool isTablet,
  ) {
    final roleColor =
        widget.isImpostor ? theme.colorScheme.error : theme.colorScheme.primary;
    final roleText = widget.isImpostor ? 'IMPOSTOR' : 'CHARACTER';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              roleColor.withOpacity(0.2),
              roleColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? size.width * 0.15 : 32,
                vertical: 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40 : 24,
                      vertical: isTablet ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: roleColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      roleText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 24 : 20,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    'You are',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: isTablet ? 28 : 22,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.isImpostor)
                    Icon(
                      Icons.masks,
                      size: isTablet ? 120 : 100,
                      color: roleColor,
                    )
                  else
                    Icon(
                      Icons.person_rounded,
                      size: isTablet ? 120 : 100,
                      color: roleColor,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    widget.isImpostor
                        ? 'The Impostor'
                        : widget.characterName ?? '',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 56 : 48,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      widget.isImpostor
                          ? 'Pretend to know the character and blend in with the others!'
                          : 'Give hints about your character without revealing too much!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: isTablet ? 18 : 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 60 : 48,
                        vertical: isTablet ? 24 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: roleColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
