import 'package:flutter/material.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

class ImposterRevealCard extends StatelessWidget {
  final Player imposter;
  final bool imposterCaught;

  const ImposterRevealCard({
    super.key,
    required this.imposter,
    required this.imposterCaught,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          children: [
            Icon(
              imposterCaught ? Icons.check_circle : Icons.cancel,
              size: isTablet ? 100 : 80,
              color: imposterCaught ? Colors.green : Colors.red,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              imposterCaught ? '🎉 Imposter Caught!' : '😈 Imposter Won!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: imposterCaught ? Colors.green : Colors.red,
                fontSize: isTablet ? 32 : 24,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'The Imposter was:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: isTablet ? 20 : 16,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isTablet ? 32 : 24,
                        child: Text(
                          imposter.username[0].toUpperCase(),
                          style: TextStyle(fontSize: isTablet ? 32 : 24),
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Flexible(
                        child: Text(
                          imposter.username,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 28 : 22,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
