import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/shared/presentation/widgets/app_bar_title.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/home_action_buttons.dart';
import 'widgets/welcome_section.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'Guest';
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              title: const AppBarTitle(title: 'Guess Party'),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.exit_to_app_rounded),
                    iconSize: 28,
                    color: Colors.white,
                    tooltip: 'Logout',
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? size.width * 0.15 : 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WelcomeSection(username: username, isTablet: isTablet),
                        SizedBox(height: isTablet ? 48 : 32),
                        HomeActionButtons(isTablet: isTablet),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
