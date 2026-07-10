import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _redirectUrl = 'com.icisland.icislandapp://login-callback/';

class AuthService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  static Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
    );
  }

  static Future<void> signInWithKakao() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: _redirectUrl,
    );
  }

  static Future<void> signInWithApple() async {
    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple 로그인에 실패했어요 (identityToken 없음)');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
    required String travelStyle,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'nickname': nickname, 'travel_style': travelStyle},
    );
  }

  static Future<void> signOut() {
    return _client.auth.signOut();
  }

  static String localizedError(String message) {
    if (message.contains('Invalid login credentials')) return '이메일 또는 비밀번호가 틀렸어요';
    if (message.contains('Email not confirmed')) return '이메일 인증이 필요해요';
    if (message.contains('already registered')) return '이미 가입된 이메일이에요';
    if (message.contains('Password should be')) return '비밀번호는 6자 이상이어야 해요';
    if (message.contains('Unable to validate email')) return '올바른 이메일 형식이 아니에요';
    return '오류가 발생했어요. 다시 시도해주세요';
  }
}
