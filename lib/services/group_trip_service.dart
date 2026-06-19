import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupTripService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;
  static String? get currentUserId => _userId;

  static const _select = '''
    *,
    group_members(user_id, profiles(nickname, avatar_url)),
    group_expenses(id, description, amount, paid_by, created_at),
    group_polls(id, question, options, is_active, created_by, created_at)
  ''';

  static Map<String, dynamic> _process(Map<String, dynamic> g) {
    final me = _userId ?? '';
    final members = ((g['group_members'] as List?) ?? []).map((m) {
      final p = m['profiles'] as Map<String, dynamic>?;
      return <String, dynamic>{
        'id': m['user_id'] as String,
        'name': m['user_id'] == me ? '나' : (p?['nickname'] as String? ?? '멤버'),
        'avatar': p?['avatar_url'] as String? ??
            'https://api.dicebear.com/7.x/avataaars/svg?seed=${m['user_id']}',
        'isOwner': m['user_id'] == g['created_by'],
      };
    }).toList();

    final expenses = List<Map<String, dynamic>>.from(
      (g['group_expenses'] as List?) ?? [],
    )..sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));

    final polls = List<Map<String, dynamic>>.from(
      (g['group_polls'] as List?) ?? [],
    )..sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));

    return {
      'id': g['id'],
      'name': g['name'],
      'destination': List<String>.from((g['destination'] as List?) ?? []),
      'startDate': g['start_date'],
      'endDate': g['end_date'],
      'inviteCode': g['invite_code'],
      'createdBy': g['created_by'],
      'members': members,
      'expenses': expenses,
      'polls': polls,
    };
  }

  static Future<Map<String, dynamic>?> getGroupById(String groupId) async {
    if (_userId == null) return null;
    final data = await _client
        .from('group_trips')
        .select(_select)
        .eq('id', groupId)
        .single();
    return _process(data as Map<String, dynamic>);
  }

  static Future<List<Map<String, dynamic>>> getMyGroups() async {
    if (_userId == null) return [];
    final memberships = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', _userId!);

    final groupIds = (memberships as List).map((m) => m['group_id'] as String).toList();
    if (groupIds.isEmpty) return [];

    final results = await Future.wait(groupIds.map(getGroupById));
    final groups = results.whereType<Map<String, dynamic>>().toList();
    groups.sort((a, b) => (b['id'] as String).compareTo(a['id'] as String));
    return groups;
  }

  static Future<Map<String, dynamic>?> getGroupByInviteCode(String code) async {
    if (_userId == null) return null;
    final data = await _client
        .from('group_trips')
        .select(_select)
        .eq('invite_code', code.toUpperCase())
        .maybeSingle();
    return data != null ? _process(data as Map<String, dynamic>) : null;
  }

  static Future<Map<String, dynamic>?> createGroup({
    required String name,
    required List<String> destination,
    required String startDate,
    required String endDate,
  }) async {
    if (_userId == null) return null;
    final code = _randomCode();
    final result = await _client.from('group_trips').insert({
      'name': name,
      'destination': destination,
      'start_date': startDate,
      'end_date': endDate,
      'invite_code': code,
      'created_by': _userId,
    }).select('id').single();

    final groupId = (result as Map)['id'] as String;
    await _client.from('group_members').insert({'group_id': groupId, 'user_id': _userId});
    return getGroupById(groupId);
  }

  static Future<bool> joinGroup(String groupId) async {
    if (_userId == null) return false;
    try {
      await _client.from('group_members').upsert(
        {'group_id': groupId, 'user_id': _userId},
        onConflict: 'group_id,user_id',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addExpense({
    required String groupId,
    required String description,
    required int amount,
  }) async {
    if (_userId == null) return false;
    try {
      await _client.from('group_expenses').insert(
          {'group_id': groupId, 'description': description, 'amount': amount, 'paid_by': _userId});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addPoll({
    required String groupId,
    required String question,
    required List<Map<String, dynamic>> options,
  }) async {
    if (_userId == null) return false;
    try {
      await _client.from('group_polls').insert({
        'group_id': groupId,
        'question': question,
        'options': options,
        'created_by': _userId,
        'is_active': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> vote({
    required String pollId,
    required String optionId,
    required List<dynamic> currentOptions,
  }) async {
    if (_userId == null) return 'error';
    for (final opt in currentOptions) {
      final votes = List<String>.from((opt['votes'] as List?) ?? []);
      if (votes.contains(_userId)) return 'already_voted';
    }
    final newOptions = currentOptions.map((opt) {
      final votes = List<String>.from((opt['votes'] as List?) ?? []);
      if (opt['id'] == optionId) votes.add(_userId!);
      return {...(opt as Map<String, dynamic>), 'votes': votes};
    }).toList();
    try {
      await _client.from('group_polls').update({'options': newOptions}).eq('id', pollId);
      return 'ok';
    } catch (_) {
      return 'error';
    }
  }

  static Future<bool> deleteGroup(String groupId) async {
    if (_userId == null) return false;
    try {
      await _client.from('group_trips').delete().eq('id', groupId).eq('created_by', _userId!);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> leaveGroup(String groupId) async {
    if (_userId == null) return false;
    try {
      await _client.from('group_members').delete().eq('group_id', groupId).eq('user_id', _userId!);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _randomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
