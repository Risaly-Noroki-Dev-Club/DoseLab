import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../shared/constants/strings.dart';

/// DoseLab is local-first: a logged-out user can still log doses and
/// view PK curves. [AuthState.requiresUnlock] is only true if the user
/// explicitly enabled an app-level lock in settings.
@immutable
class AuthState {
  const AuthState({
    this.userId,
    this.requiresUnlock = false,
    this.isAuthenticated = false,
  });

  final String? userId;
  final bool requiresUnlock;
  final bool isAuthenticated;

  AuthState copyWith({
    String? userId,
    bool? requiresUnlock,
    bool? isAuthenticated,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      requiresUnlock: requiresUnlock ?? this.requiresUnlock,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Read persisted hint synchronously by hitting secure storage at
    // boot; an async refresh fires immediately to load the real token.
    _restore();
    return const AuthState();
  }

  Future<void> _restore() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: StorageKeys.accessToken);
    final lockEnabled = await storage.read(key: StorageKeys.lockEnabled);
    state = state.copyWith(
      isAuthenticated: token != null && token.isNotEmpty,
      requiresUnlock: lockEnabled == 'true',
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) return;
    final storage = ref.read(secureStorageProvider);
    final api = ref.read(apiClientProvider);

    try {
      final resp = await api.backend.post(
        ApiPaths.authLogin,
        data: {'email': email, 'password': password},
      );
      final token = (resp.data as Map)['access_token'] as String?;
      if (token != null && token.isNotEmpty) {
        await storage.write(key: StorageKeys.accessToken, value: token);
        state = state.copyWith(
          isAuthenticated: true,
          userId: email,
          requiresUnlock: false,
        );
        return;
      }
    } catch (_) {
      // Backend unreachable — fall back to local-only session
    }
    await storage.write(key: StorageKeys.accessToken, value: 'local-only');
    state = state.copyWith(
      isAuthenticated: true,
      userId: email,
      requiresUnlock: false,
    );
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(requiresUnlock: false);
  }

  Future<void> signOut() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: StorageKeys.accessToken);
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
