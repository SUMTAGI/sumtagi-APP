import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  const ChatMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

// 대화가 길어질수록 토큰 사용량이 늘어나므로 최근 6턴만 전송 (islandChat.ts와 동일 기준)
const _maxHistoryTurns = 6;

Future<String> askIslandChat(List<ChatMessage> history) async {
  final messages = history.length > _maxHistoryTurns
      ? history.sublist(history.length - _maxHistoryTurns)
      : history;

  final response = await Supabase.instance.client.functions.invoke(
    'island-chat',
    body: {'messages': messages.map((m) => m.toJson()).toList()},
  );

  final data = response.data;
  if (data is! Map || data['ok'] != true || data['reply'] == null) {
    throw Exception('상담 응답 오류');
  }
  return data['reply'] as String;
}
