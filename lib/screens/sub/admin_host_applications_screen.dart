import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_host_service.dart';
import '../../services/host_service.dart';
import '../../theme/app_colors.dart';

class AdminHostApplicationsScreen extends StatefulWidget {
  const AdminHostApplicationsScreen({super.key});
  @override
  State<AdminHostApplicationsScreen> createState() => _AdminHostApplicationsScreenState();
}

class _AdminHostApplicationsScreenState extends State<AdminHostApplicationsScreen> {
  static const _filters = [
    {'key': 'all', 'label': '전체'},
    {'key': 'pending', 'label': '검토 중'},
    {'key': 'approved', 'label': '승인'},
    {'key': 'rejected', 'label': '반려'},
  ];

  bool _checkingRole = true;
  bool _loading = true;
  String? _error;
  String _filter = 'pending';
  List<HostApplicationWithProfile> _applications = [];

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final role = await HostService.getMyRole();
    if (!mounted) return;
    if (role != 'admin') {
      context.go('/my');
      return;
    }
    setState(() => _checkingRole = false);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AdminHostService.getHostApplications();
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _error = result.error ?? '목록을 불러오지 못했어요';
        _loading = false;
      });
      return;
    }
    setState(() {
      _applications = result.data ?? [];
      _loading = false;
    });
  }

  Map<String, int> get _counts => {
        'all': _applications.length,
        'pending': _applications.where((a) => a.application.status == 'pending').length,
        'approved': _applications.where((a) => a.application.status == 'approved').length,
        'rejected': _applications.where((a) => a.application.status == 'rejected').length,
      };

  List<HostApplicationWithProfile> get _filtered =>
      _filter == 'all' ? _applications : _applications.where((a) => a.application.status == _filter).toList();

  void _openDetail(HostApplicationWithProfile app) async {
    final updated = await Navigator.of(context).push<HostApplicationWithProfile>(
      MaterialPageRoute(builder: (_) => _HostApplicationDetailScreen(application: app)),
    );
    if (updated != null && mounted) {
      setState(() {
        final idx = _applications.indexWhere((a) => a.application.id == updated.application.id);
        if (idx != -1) _applications[idx] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    final counts = _counts;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('숙소 운영자 신청 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('신청서를 검토하고 승인 또는 반려해요', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final key = _filters[i]['key']!;
                  final label = _filters[i]['label']!;
                  final isActive = _filter == key;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.blue600 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isActive ? AppColors.blue600 : AppColors.gray200),
                      ),
                      child: Text(
                        '$label ${counts[key] ?? 0}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? Colors.white : AppColors.gray600),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.red500),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                        const SizedBox(height: 12),
                        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('다시 시도')),
                      ],
                    ),
                  )
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inbox_outlined, size: 40, color: AppColors.gray300),
                                const SizedBox(height: 12),
                                Text(
                                  _filter == 'pending' ? '검토 대기 중인 신청이 없어요' : '해당하는 신청이 없어요',
                                  style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final app = _filtered[i].application;
                              return GestureDetector(
                                onTap: () => _openDetail(_filtered[i]),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.gray200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(app.businessName,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gray900),
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                          _StatusBadge(status: app.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${app.representativeName ?? "대표자 미입력"} · ${app.phone}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(_formatDateTime(app.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return '${dt.year}년 ${dt.month}월 ${dt.day}일 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} 신청';
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, label, icon) = switch (status) {
      'approved' => (AppColors.blue50, AppColors.blue100, AppColors.blue700, '승인', Icons.check_circle_outline_rounded),
      'rejected' => (AppColors.red50, AppColors.red100, AppColors.red500, '반려', Icons.cancel_outlined),
      _ => (const Color(0xFFFFFBEB), const Color(0xFFFDE68A), const Color(0xFFB45309), '검토 중', Icons.fact_check_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}

class _HostApplicationDetailScreen extends StatefulWidget {
  final HostApplicationWithProfile application;
  const _HostApplicationDetailScreen({required this.application});

  @override
  State<_HostApplicationDetailScreen> createState() => _HostApplicationDetailScreenState();
}

class _HostApplicationDetailScreenState extends State<_HostApplicationDetailScreen> {
  late HostApplicationWithProfile _app;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _app = widget.application;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신청을 승인할까요?'),
        content: const Text('이 신청을 승인하면 해당 사용자가 호스트 권한을 갖게 됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('승인하기')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processing = true);
    final result = await AdminHostService.approveHostApplication(_app.application.id);
    if (mounted) setState(() => _processing = false);
    if (!result.success) {
      _toast(result.error ?? '승인에 실패했어요. 다시 시도해주세요');
      return;
    }
    setState(() => _app = HostApplicationWithProfile(
          application: _app.application.copyWith(status: 'approved', rejectionReason: null),
          nickname: _app.nickname,
        ));
    _toast('호스트로 승인됐어요');
  }

  Future<void> _openRejectDialog() async {
    final reasonCtrl = TextEditingController();
    String? error;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('신청 반려'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('반려 사유는 신청자에게 그대로 전달돼요. 구체적으로 작성해주세요.', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '예: 제출하신 사업자등록번호를 확인할 수 없습니다.',
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red500),
              onPressed: () {
                final trimmed = reasonCtrl.text.trim();
                if (trimmed.length < 5) {
                  setDialogState(() => error = '반려 사유를 5자 이상 입력해주세요');
                  return;
                }
                Navigator.pop(context, trimmed);
              },
              child: const Text('반려하기'),
            ),
          ],
        ),
      ),
    );
    if (reason == null) return;

    setState(() => _processing = true);
    final result = await AdminHostService.rejectHostApplication(_app.application.id, reason);
    if (mounted) setState(() => _processing = false);
    if (!result.success) {
      _toast(result.error ?? '반려 처리에 실패했어요. 다시 시도해주세요');
      return;
    }
    setState(() => _app = HostApplicationWithProfile(
          application: _app.application.copyWith(status: 'rejected', rejectionReason: reason),
          nickname: _app.nickname,
        ));
    _toast('신청을 반려했어요');
  }

  @override
  Widget build(BuildContext context) {
    final app = _app.application;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _app);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(app.businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _app),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(app.businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900))),
                _StatusBadge(status: app.status),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(icon: Icons.person_outline_rounded, label: '신청자', value: _app.nickname ?? '알 수 없음'),
            _DetailRow(icon: Icons.badge_outlined, label: '대표자명', value: app.representativeName ?? '-'),
            _DetailRow(icon: Icons.phone_outlined, label: '연락처', value: app.phone),
            _DetailRow(icon: Icons.tag_rounded, label: '사업자등록번호', value: app.businessRegistrationNumber ?? '-'),
            _DetailRow(icon: Icons.calendar_today_outlined, label: '신청일', value: _formatDateTime(app.createdAt)),
            _DetailRow(icon: Icons.access_time_rounded, label: '최근 수정일', value: _formatDateTime(app.updatedAt)),
            const SizedBox(height: 12),
            if (app.status == 'rejected' && (app.rejectionReason?.isNotEmpty ?? false)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.red100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('반려 사유', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.red500)),
                    const SizedBox(height: 4),
                    Text(app.rejectionReason!, style: const TextStyle(fontSize: 14, color: AppColors.red700, height: 1.4)),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 8),
            if (app.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _processing ? null : _confirmApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('승인'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processing ? null : _openRejectDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red500,
                        side: const BorderSide(color: AppColors.red100, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('반려'),
                    ),
                  ),
                ],
              )
            else if (app.status == 'approved')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.blue700),
                    SizedBox(width: 8),
                    Text('승인 완료된 신청이에요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blue700)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, size: 18, color: AppColors.gray500),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('반려된 신청이에요. 재신청하면 다시 검토 목록에 나타나요.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray500)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.gray400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
