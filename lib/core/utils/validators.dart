import 'package:profanity_filter/profanity_filter.dart';
  
  class Validators {
    static final _profanityFilter = ProfanityFilter();
  
    // Username Validator with profanity filter
    static String? username(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter a username';
      }
      
      final trimmed = value.trim();
      
      if (trimmed.length < 2) {
        return 'Username must be at least 2 characters';
      }
      
      if (trimmed.length > 20) {
        return 'Username must be less than 20 characters';
      }
      
      // Check for special characters
      final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
      if (!usernameRegex.hasMatch(trimmed)) {
        return 'Username can only contain letters, numbers and underscore';
      }
      
      // Check for profanity
      if (_profanityFilter.hasProfanity(trimmed)) {
        return 'Username contains inappropriate content';
      }
      
      return null;
    }
  
    // Password Validator
    static String? password(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      if (value.length > 50) {
        return 'Password must be less than 50 characters';
      }
      return null;
    }
  
    // Room Code Validator
    static String? roomCode(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter room code';
      }
      if (value.trim().length < 4) {
        return 'Room code must be at least 4 characters';
      }
      if (value.trim().length > 8) {
        return 'Room code must be less than 8 characters';
      }
      return null;
    }
  }