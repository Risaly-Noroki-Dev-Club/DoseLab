import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../shared/constants/strings.dart';

/// DoseLab is local-first: all data is stored locally via Drift.
/// [AuthState.requiresUnlock] is only true if the user
/// explicitly enabled an app-level lock in settings.
@immutable
class AuthState {
  const AuthState({
    this.requiresUnlock = false,
  });

  final bool requiresUnlock;

  AuthState copyWith({
    bool? requiresUnlock,
  }) {
    return AuthState(
      requiresUnlock: requiresUnlock ?? this.requiresUnlock,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState();
  }

  Future<void> _restore() async {
    final storage = ref.read(secureStorageProvider);
    final lockEnabled = await storage.read(key: StorageKeys.lockEnabled);
    state = state.copyWith(
      requiresUnlock: lockEnabled == 'true',
    );
  }

  Future<void> unlock() async {
    state = state.copyWith(requiresUnlock: false);
  }

  Future<void> signOut() async {
    state = const AuthState();
  }

  Future<void> setLockEnabled(bool enabled) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(
      key: StorageKeys.lockEnabled,
      value: enabled ? 'true' : 'false',
    );
    state = state.copyWith(requiresUnlock: enabled);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
