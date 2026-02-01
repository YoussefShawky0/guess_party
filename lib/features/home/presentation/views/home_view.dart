import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/home/presentation/cubit/home_state.dart';

import 'widgets/home_action_buttons.dart';
import 'widgets/welcome_section.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<HomeCubit>()..loadUserInfo(),
      child: const HomeContent(),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/Front_Imposter_ingroup.png',
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      'Guess Party',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Settings Button
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.gear, size: 18),
                    color: AppColors.textPrimary,
                    tooltip: 'Settings',
                    onPressed: () {
                      context.push('/settings');
                    },
                  ),
                  // Logout Button
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.rightFromBracket,
                      size: 18,
                    ),
                    color: AppColors.error,
                    tooltip: 'Logout',
                    onPressed: () {
                      context.read<HomeCubit>().signOutUser();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<HomeCubit, HomeState>(
                listener: (context, state) {
                  if (state is HomeSignedOut) {
                    context.go('/auth');
                  }
                },
                builder: (context, state) {
                  if (state is HomeLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (state is HomeError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  if (state is HomeLoaded) {
                    return Center(
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
                              WelcomeSection(
                                username: state.userInfo.username,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 48 : 32),
                              HomeActionButtons(isTablet: isTablet),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
