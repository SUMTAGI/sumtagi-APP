import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  static Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
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
