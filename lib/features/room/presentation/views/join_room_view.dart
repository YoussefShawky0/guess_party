import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/features/room/presentation/views/widgets/join_room_button.dart';
import 'package:guess_party/features/room/presentation/views/widgets/join_room_header.dart';
import 'package:guess_party/features/room/presentation/views/widgets/room_code_input.dart';
import 'package:guess_party/shared/widgets/app_bar_title.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _joinRoom() {
    if (_formKey.currentState!.validate()) {
      final user = Supabase.instance.client.auth.currentUser;
      final username = user?.userMetadata?['username'] ?? 'Guest';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const AppBarTitle(title: 'Join Room'),
        centerTitle: true,
      ),
      body: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state is RoomError) {
            ErrorSnackBar.show(context, state.message);
          }

          if (state is RoomWithPlayerCreated) {
            context.go('/room/${state.room.id}/waiting');
          }
        },
        builder: (context, state) {
          final isLoading = state is RoomLoading;

          return SafeArea(
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
                    RoomCodeInput(controller: _roomCodeController),
                    SizedBox(height: isTablet ? 40 : 32),
                    JoinRoomButton(onPressed: _joinRoom, isLoading: isLoading),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
