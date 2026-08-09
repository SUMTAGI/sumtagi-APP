import 'package:flutter/material.dart';
import '../../services/host_service.dart';
import '../../theme/app_colors.dart';

class HostApplyScreen extends StatefulWidget {
  const HostApplyScreen({super.key});
  @override
  State<HostApplyScreen> createState() => _HostApplyScreenState();
}

class _HostApplyScreenState extends State<HostApplyScreen> {
  static const _steps = [
    {'label': '신청서 작성', 'icon': Icons.description_outlined},
    {'label': '관리자 검토', 'icon': Icons.fact_check_outlined},
    {'label': '승인', 'icon': Icons.check_circle_outline_rounded},
    {'label': '숙소 등록 가능', 'icon': Icons.rocket_launch_outlined},
  ];

  HostApplication? _application;
  bool _fetching = true;
  bool _saving = false;
  bool _resubmitting = false;

  final _businessNameCtrl = TextEditingController();
  final _representativeNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessRegNumberCtrl = TextEditingController();
  String? _businessNameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _representativeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _businessRegNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app = await HostService.getMyHostApplication();
    if (mounted) {
      setState(() {
        _application = app;
        if (app != null) {
          _businessNameCtrl.text = app.businessName;
          _representativeNameCtrl.text = app.representativeName ?? '';
          _phoneCtrl.text = app.phone;
          _businessRegNumberCtrl.text = app.businessRegistrationNumber ?? '';
        }
        _fetching = false;
      });
    }
  }

  bool _validate() {
    setState(() {
      _businessNameError = _businessNameCtrl.text.trim().isEmpty ? '상호명을 입력해주세요' : null;
      _phoneError = _phoneCtrl.text.trim().isEmpty ? '연락처를 입력해주세요' : null;
    });
    return _businessNameError == null && _phoneError == null;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_saving || _resubmitting) return;
    if (!_validate()) {
      _toast('필수 항목을 확인해주세요');
      return;
    }
    setState(() => _saving = true);
    final result = _application != null
        ? await HostService.updateHostApplication(
            businessName: _businessNameCtrl.text,
            representativeName: _representativeNameCtrl.text,
            phone: _phoneCtrl.text,
            businessRegistrationNumber: _businessRegNumberCtrl.text,
          )
        : await HostService.createHostApplication(
            businessName: _businessNameCtrl.text,
            representativeName: _representativeNameCtrl.text,
            phone: _phoneCtrl.text,
            businessRegistrationNumber: _businessRegNumberCtrl.text,
          );
    if (mounted) setState(() => _saving = false);
    if (result == null) {
      _toast(_application != null ? '저장에 실패했어요. 다시 시도해주세요' : '신청에 실패했어요. 다시 시도해주세요');
      return;
    }
    if (mounted) setState(() => _application = result);
    _toast(_application != null ? '신청 정보가 저장됐어요' : '숙소 운영자 신청이 접수됐어요');
  }

  Future<void> _resubmit() async {
    if (_saving || _resubmitting) return;
    if (!_validate()) {
      _toast('필수 항목을 확인해주세요');
      return;
    }
    setState(() => _resubmitting = true);
    final updated = await HostService.updateHostApplication(
      businessName: _businessNameCtrl.text,
      representativeName: _representativeNameCtrl.text,
      phone: _phoneCtrl.text,
      businessRegistrationNumber: _businessRegNumberCtrl.text,
    );
    if (updated == null) {
      if (mounted) setState(() => _resubmitting = false);
      _toast('저장에 실패했어요. 다시 시도해주세요');
      return;
    }
    final ok = await HostService.resubmitHostApplication();
    if (mounted) setState(() => _resubmitting = false);
    if (!ok) {
      _toast('재신청에 실패했어요. 다시 시도해주세요');
      return;
    }
    if (mounted) setState(() => _application = updated.copyWith(status: 'pending', rejectionReason: null));
    _toast('재신청이 접수됐어요');
  }

  int get _stepIndex {
    final status = _application?.status;
    if (status == 'approved') return 2;
    if (status == 'pending' || status == 'rejected') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = _application?.status;
    final isApproved = status == 'approved';
    final isEditable = _application == null || status == 'pending' || status == 'rejected';
    final stepIdx = _stepIndex;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('숙소 운영자 신청', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('섬타기에 숙소를 등록하고 게스트를 맞이해보세요', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 입점 절차 안내
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: List.generate(_steps.length, (i) {
                final isRejectedFork = status == 'rejected' && i == 1;
                final done = i < stepIdx || (i == stepIdx && isApproved);
                final current = i == stepIdx && !isApproved;
                final circleColor = isRejectedFork
                    ? AppColors.red50
                    : done
                        ? AppColors.blue600
                        : Colors.white;
                final borderColor = isRejectedFork
                    ? const Color(0xFFFCA5A5)
                    : done
                        ? AppColors.blue600
                        : current
                            ? AppColors.blue600
                            : AppColors.gray200;
                final iconColor = isRejectedFork
                    ? AppColors.red500
                    : done
                        ? Colors.white
                        : current
                            ? AppColors.blue600
                            : AppColors.gray300;
                final labelColor = isRejectedFork
                    ? AppColors.red500
                    : (done || current)
                        ? AppColors.gray900
                        : AppColors.gray400;
                return Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (i > 0)
                            Positioned(
                              right: 16,
                              child: Container(height: 2, width: 200, color: i <= stepIdx ? AppColors.blue600 : AppColors.gray200),
                            ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: circleColor,
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Icon(_steps[i]['icon'] as IconData, size: 16, color: iconColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _steps[i]['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: labelColor),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // 상태 배지 + 안내 문구
          if (status != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusBg(status),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusBorder(status)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_statusIcon(status), size: 16, color: _statusText(status)),
                      const SizedBox(width: 6),
                      Text(_statusLabel(status), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _statusText(status))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'pending'
                        ? '입점 신청을 검토 중입니다. 검토는 영업일 기준 1~3일 정도 소요돼요.'
                        : status == 'approved'
                            ? '호스트 승인이 완료되었습니다. 숙소 등록 기능은 곧 열릴 예정이에요.'
                            : (_application?.rejectionReason?.isNotEmpty == true
                                ? _application!.rejectionReason!
                                : '제출하신 정보를 다시 확인한 뒤 재신청해주세요.'),
                    style: TextStyle(fontSize: 13, color: _statusText(status), height: 1.4),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.blue100),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.blue600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '신청서 제출 후 관리자 검토를 거쳐 승인되면 숙소를 등록할 수 있어요.',
                      style: TextStyle(fontSize: 13, color: AppColors.blue700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          _Field(
            label: '상호명',
            required: true,
            controller: _businessNameCtrl,
            enabled: isEditable,
            hint: '예: 섬타기 게스트하우스',
            error: _businessNameError,
          ),
          const SizedBox(height: 16),
          _Field(
            label: '대표자명',
            controller: _representativeNameCtrl,
            enabled: isEditable,
            hint: '선택 입력',
          ),
          const SizedBox(height: 16),
          _Field(
            label: '연락처',
            required: true,
            controller: _phoneCtrl,
            enabled: isEditable,
            hint: '010-0000-0000',
            error: _phoneError,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _Field(
            label: '사업자등록번호',
            controller: _businessRegNumberCtrl,
            enabled: isEditable,
            hint: '선택 입력',
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: isApproved
                ? ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                    label: const Text('호스트 대시보드 (준비 중)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gray100,
                      disabledBackgroundColor: AppColors.gray100,
                      foregroundColor: AppColors.gray400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  )
                : ElevatedButton(
                    onPressed: (_saving || _resubmitting) ? null : (status == 'rejected' ? _resubmit : _submit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.blue200,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      status == 'rejected'
                          ? (_resubmitting ? '재신청 처리 중...' : '재신청하기')
                          : (_saving ? '처리 중...' : (_application != null ? '저장하기' : '숙소 운영자 신청')),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _statusBg(String status) => switch (status) {
        'pending' => const Color(0xFFFFFBEB),
        'approved' => AppColors.blue50,
        _ => AppColors.red50,
      };
  Color _statusBorder(String status) => switch (status) {
        'pending' => const Color(0xFFFDE68A),
        'approved' => AppColors.blue100,
        _ => AppColors.red100,
      };
  Color _statusText(String status) => switch (status) {
        'pending' => const Color(0xFFB45309),
        'approved' => AppColors.blue700,
        _ => AppColors.red500,
      };
  IconData _statusIcon(String status) => switch (status) {
        'pending' => Icons.fact_check_outlined,
        'approved' => Icons.check_circle_outline_rounded,
        _ => Icons.cancel_outlined,
      };
  String _statusLabel(String status) => switch (status) {
        'pending' => '검토 중',
        'approved' => '승인 완료',
        _ => '반려됨',
      };
}

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final String? error;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    this.required = false,
    required this.controller,
    required this.enabled,
    required this.hint,
    this.error,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.red500)),
          ]),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: !enabled,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? AppColors.red500 : AppColors.gray200, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? AppColors.red500 : AppColors.gray200, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.red500)),
        ],
      ],
    );
  }
}
