// 관리자 전용 — 호스트 신청 목록 조회 + 승인/반려.
// 승인/반려는 절대 테이블을 직접 UPDATE하지 않고 항상 approve_host_application /
// reject_host_application RPC만 호출한다(WEB adminHostService.ts와 동일 원칙).
// 두 함수 모두 내부에서 auth.uid() 기준 profiles.role='admin' 여부를 재검증하므로,
// admin 여부의 최종 보안선은 DB에 있다 — 클라이언트는 admin의 uuid를 넘기지 않는다.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'host_service.dart' show HostApplication;

class HostApplicationWithProfile {
  final HostApplication application;
  final String? nickname;
  const HostApplicationWithProfile({required this.application, this.nickname});

  factory HostApplicationWithProfile.fromMap(Map<String, dynamic> m) => HostApplicationWithProfile(
        application: HostApplication.fromMap(m),
        nickname: (m['profiles'] as Map?)?['nickname'] as String?,
      );
}

class AdminHostResult<T> {
  final bool success;
  final T? data;
  final String? error;
  const AdminHostResult({required this.success, this.data, this.error});
}

class AdminHostService {
  static final _client = Supabase.instance.client;

  static Future<AdminHostResult<List<HostApplicationWithProfile>>> getHostApplications({String? status}) async {
    try {
      var query = _client.from('hosts').select('*, profiles(nickname)');
      final data = await (status != null ? query.eq('status', status) : query).order('created_at', ascending: false);
      final list = (data as List)
          .map((m) => HostApplicationWithProfile.fromMap(m as Map<String, dynamic>))
          .toList();
      return AdminHostResult(success: true, data: list);
    } catch (e) {
      return AdminHostResult(success: false, error: e.toString());
    }
  }

  static Future<AdminHostResult<void>> approveHostApplication(String hostId) async {
    try {
      await _client.rpc('approve_host_application', params: {'p_host_id': hostId});
      return const AdminHostResult(success: true);
    } catch (e) {
      return AdminHostResult(success: false, error: e.toString());
    }
  }

  static Future<AdminHostResult<void>> rejectHostApplication(String hostId, String reason) async {
    try {
      await _client.rpc('reject_host_application', params: {'p_host_id': hostId, 'p_reason': reason});
      return const AdminHostResult(success: true);
    } catch (e) {
      return AdminHostResult(success: false, error: e.toString());
    }
  }
}
