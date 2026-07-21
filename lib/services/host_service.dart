// 숙소 운영자 신청/재신청 + 내 role 조회.
// WEB(src/lib/hostService.ts)을 미러링. 승인/반려는 관리자 전용이라
// admin_host_service.dart(approve_host_application/reject_host_application RPC)에서 처리한다.
import 'package:supabase_flutter/supabase_flutter.dart';

class HostApplication {
  final String id;
  final String businessName;
  final String? representativeName;
  final String phone;
  final String? businessRegistrationNumber;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;

  const HostApplication({
    required this.id,
    required this.businessName,
    this.representativeName,
    required this.phone,
    this.businessRegistrationNumber,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HostApplication.fromMap(Map<String, dynamic> m) => HostApplication(
        id: m['id'] as String,
        businessName: m['business_name'] as String,
        representativeName: m['representative_name'] as String?,
        phone: m['phone'] as String,
        businessRegistrationNumber: m['business_registration_number'] as String?,
        status: m['status'] as String,
        rejectionReason: m['rejection_reason'] as String?,
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
      );

  HostApplication copyWith({String? status, String? rejectionReason}) => HostApplication(
        id: id,
        businessName: businessName,
        representativeName: representativeName,
        phone: phone,
        businessRegistrationNumber: businessRegistrationNumber,
        status: status ?? this.status,
        rejectionReason: rejectionReason,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class HostService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static Future<HostApplication?> getMyHostApplication() async {
    if (_userId == null) return null;
    try {
      final data = await _client.from('hosts').select().eq('id', _userId!).maybeSingle();
      return data == null ? null : HostApplication.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  static Future<HostApplication?> createHostApplication({
    required String businessName,
    String? representativeName,
    required String phone,
    String? businessRegistrationNumber,
  }) async {
    if (_userId == null) return null;
    try {
      final data = await _client.from('hosts').insert({
        'id': _userId,
        'business_name': businessName.trim(),
        'representative_name': _blankToNull(representativeName),
        'phone': phone.trim(),
        'business_registration_number': _blankToNull(businessRegistrationNumber),
      }).select().single();
      return HostApplication.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  static Future<HostApplication?> updateHostApplication({
    required String businessName,
    String? representativeName,
    required String phone,
    String? businessRegistrationNumber,
  }) async {
    if (_userId == null) return null;
    try {
      final data = await _client
          .from('hosts')
          .update({
            'business_name': businessName.trim(),
            'representative_name': _blankToNull(representativeName),
            'phone': phone.trim(),
            'business_registration_number': _blankToNull(businessRegistrationNumber),
          })
          .eq('id', _userId!)
          .select()
          .single();
      return HostApplication.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> resubmitHostApplication() async {
    if (_userId == null) return false;
    try {
      await _client.rpc('resubmit_host_application');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// profiles.role 조회 ('user'|'host'|'admin'). 미로그인/조회 실패 시 'user'.
  static Future<String> getMyRole() async {
    if (_userId == null) return 'user';
    try {
      final data = await _client.from('profiles').select('role').eq('id', _userId!).maybeSingle();
      return (data?['role'] as String?) ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  static String? _blankToNull(String? v) => (v?.trim().isNotEmpty ?? false) ? v!.trim() : null;
}
