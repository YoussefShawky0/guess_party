import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/features/room/presentation/views/widgets/join_room_button.dart';
import 'package:guess_party/features/room/presentation/views/widgets/join_room_header.dart';
import 'package:guess_party/features/room/presentation/views/widgets/room_code_input.dart';
import 'package:guess_party/shared/widgets/app_bar_title.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:guess_party/l10n/l10n.dart';

class JoinRoomView extends StatelessWidget {
  const JoinRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<RoomCubit>(),
      child: const JoinRoomContent(),
    );
  }
}

class JoinRoomContent extends StatefulWidget {
  const JoinRoomContent({super.key});

  @override
  State<JoinRoomContent> createState() => _JoinRoomContentState();
}

class _JoinRoomContentState extends State<JoinRoomContent> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();
  String? _roomCodeErrorMessage;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _clearRoomCodeError() {
    if (_roomCodeErrorMessage != null) {
      setState(() => _roomCodeErrorMessage = null);
    }
  }

  void _joinRoom() {
    if (_formKey.currentState!.validate()) {
      setState(() => _roomCodeErrorMessage = null);
      final username = di.sl<AuthSessionService>().currentUsername;

      context.read<RoomCubit>().joinRoom(
        roomCode: _roomCodeController.text.trim(),
        username: username,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).surface,
        title: AppBarTitle(title: context.l10n.joinRoom),
        centerTitle: true,
      ),
      body: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state is RoomError) {
            if (state.message.toLowerCase().contains('room not found')) {
              setState(() {
                _roomCodeErrorMessage = state.message;
              });
              ErrorSnackBar.showRoomCodeError(context);
            } else {
              if (_roomCodeErrorMessage != null) {
                setState(() => _roomCodeErrorMessage = null);
              }
              ErrorSnackBar.show(context, state.message);
            }
          }

          if (state is RoomWithPlayerCreated) {
            context.go(AppRoutes.roomWaiting(state.room.id));
          }
        },
        builder: (context, state) {
          final isLoading = state is RoomLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.25 : 24,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const JoinRoomHeader(),
                      SizedBox(height: isTablet ? 32 : 24),
                      RoomCodeInput(
                        controller: _roomCodeController,
                        onChanged: _clearRoomCodeError,
                        hasError: _roomCodeErrorMessage != null,
                      ),
                      if (_roomCodeErrorMessage != null) ...[
                        SizedBox(height: isTablet ? 16 : 12),
                        _buildRoomCodeErrorBanner(isTablet),
                      ],
                      SizedBox(height: isTablet ? 40 : 32),
                      JoinRoomButton(
                        onPressed: _joinRoom,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomCodeErrorBanner(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.cancel_rounded,
              color: AppColors.error,
              size: isTablet ? 26 : 22,
            ),
          ),
          SizedBox(width: isTablet ? 14 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.roomNotFound,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    fontSize: isTablet ? 17 : 15,
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 3),
                Text(
                  context.l10n.roomNotFoundHelp,
                  style: TextStyle(
                    color: AppColors.errorLight,
                    fontSize: isTablet ? 14 : 13,
                    height: 1.4,
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
