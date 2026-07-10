import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_trip_service.dart';
import '../../theme/app_colors.dart';

class GroupTripScreen extends StatefulWidget {
  const GroupTripScreen({super.key});
  @override
  State<GroupTripScreen> createState() => _GroupTripScreenState();
}

class _GroupTripScreenState extends State<GroupTripScreen> {
  List<Map<String, dynamic>> _groups = [];
  String? _activeGroupId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await GroupTripService.getMyGroups();
    if (!mounted) return;
    setState(() {
      _groups = data;
      if (data.isNotEmpty) _activeGroupId ??= data.first['id'] as String;
      _isLoading = false;
    });
  }

  Future<void> _refreshActive() async {
    if (_activeGroupId == null) return;
    final updated = await GroupTripService.getGroupById(_activeGroupId!);
    if (!mounted || updated == null) return;
    setState(() => _groups = _groups.map((g) => g['id'] == _activeGroupId ? updated : g).toList());
  }

  Map<String, dynamic>? get _activeGroup =>
      _groups.where((g) => g['id'] == _activeGroupId).firstOrNull;

  void _copyInviteLink(String code) {
    Clipboard.setData(ClipboardData(text: 'https://sumtagi-web.vercel.app/group-join/$code'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 링크가 복사됐어요')));
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('코드가 복사됐어요')));
  }

  // ── 그룹 삭제 / 나가기 ────────────────────────────────────
  Future<void> _handleDeleteGroup(Map<String, dynamic> group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('그룹 삭제'),
        content: Text('"${group['name']}" 그룹을 삭제할까요?\n모든 데이터가 사라져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await GroupTripService.deleteGroup(group['id'] as String);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제에 실패했어요')));
      return;
    }
    setState(() {
      _groups = _groups.where((g) => g['id'] != group['id']).toList();
      _activeGroupId = _groups.isNotEmpty ? _groups.first['id'] as String : null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹이 삭제됐어요')));
  }

  Future<void> _handleLeaveGroup(Map<String, dynamic> group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('그룹 나가기'),
        content: Text('"${group['name']}" 그룹에서 나갈까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('나가기', style: TextStyle(color: AppColors.gray700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await GroupTripService.leaveGroup(group['id'] as String);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('나가기에 실패했어요')));
      return;
    }
    setState(() {
      _groups = _groups.where((g) => g['id'] != group['id']).toList();
      _activeGroupId = _groups.isNotEmpty ? _groups.first['id'] as String : null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹에서 나왔어요')));
  }

  // ── 그룹 만들기 Bottom Sheet ──────────────────────────────
  void _showCreateSheet() {
    final nameCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    bool creating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Future<void> submit() async {
          if (nameCtrl.text.isEmpty || destCtrl.text.isEmpty || startCtrl.text.isEmpty || endCtrl.text.isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요')));
            return;
          }
          set(() => creating = true);
          final dest = destCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          final group = await GroupTripService.createGroup(
            name: nameCtrl.text,
            destination: dest,
            startDate: startCtrl.text,
            endDate: endCtrl.text,
          );
          if (!mounted) return;
          Navigator.pop(ctx);
          if (group == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹 생성에 실패했어요')));
            return;
          }
          setState(() {
            _groups = [group, ..._groups];
            _activeGroupId = group['id'] as String;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹이 생성됐어요!')));
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('그룹 만들기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 20),
                _field('그룹 이름', nameCtrl, '예: 여름 백령도 여행'),
                const SizedBox(height: 12),
                _field('목적지', destCtrl, '예: 백령도, 대청도'),
                const SizedBox(height: 12),
                _field('출발일', startCtrl, 'YYYY-MM-DD', type: TextInputType.datetime),
                const SizedBox(height: 12),
                _field('귀가일', endCtrl, 'YYYY-MM-DD', type: TextInputType.datetime),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: creating ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: creating
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('그룹 만들기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── 코드 참여 Bottom Sheet ─────────────────────────────────
  void _showJoinSheet() {
    final codeCtrl = TextEditingController();
    bool joining = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Future<void> join() async {
          final code = codeCtrl.text.trim().toUpperCase();
          if (code.isEmpty) return;
          set(() => joining = true);
          final group = await GroupTripService.getGroupByInviteCode(code);
          if (group == null) {
            set(() => joining = false);
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('유효하지 않은 초대 코드예요')));
            return;
          }
          if (_groups.any((g) => g['id'] == group['id'])) {
            Navigator.pop(ctx);
            setState(() => _activeGroupId = group['id'] as String);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 참여한 그룹이에요')));
            return;
          }
          final ok = await GroupTripService.joinGroup(group['id'] as String);
          if (!mounted) return;
          Navigator.pop(ctx);
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('참여에 실패했어요')));
            return;
          }
          final joined = await GroupTripService.getGroupById(group['id'] as String);
          if (joined != null) {
            setState(() {
              _groups = [joined, ..._groups];
              _activeGroupId = joined['id'] as String;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${group['name']} 그룹에 참여했어요!')));
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('초대 코드로 참여', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 4),
                const Text('친구에게 받은 6자리 코드를 입력하세요', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                const SizedBox(height: 20),
                TextField(
                  controller: codeCtrl,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.blue600),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'XXXXXX',
                    hintStyle: const TextStyle(fontSize: 28, letterSpacing: 8, color: AppColors.gray300),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (_) => join(),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.gray300),
                      ),
                      child: const Text('취소', style: TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: joining ? null : join,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: joining
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('참여하기', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── 지출 추가 Bottom Sheet ─────────────────────────────────
  void _showAddExpenseSheet(String groupId) {
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Future<void> save() async {
          if (descCtrl.text.isEmpty || amtCtrl.text.isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요')));
            return;
          }
          set(() => saving = true);
          final ok = await GroupTripService.addExpense(
            groupId: groupId,
            description: descCtrl.text,
            amount: int.tryParse(amtCtrl.text) ?? 0,
          );
          if (!mounted) return;
          Navigator.pop(ctx);
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('지출이 추가됐어요')));
            await _refreshActive();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장에 실패했어요')));
          }
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('지출 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 20),
                _field('지출 내용', descCtrl, '예: 점심 식사'),
                const SizedBox(height: 12),
                _field('금액', amtCtrl, '10000', type: TextInputType.number),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppColors.gray300)), child: const Text('취소', style: TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: saving ? null : save, style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('추가', style: TextStyle(fontWeight: FontWeight.bold)))),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── 투표 만들기 Bottom Sheet ───────────────────────────────
  void _showAddPollSheet(String groupId) {
    final qCtrl = TextEditingController();
    final opt1Ctrl = TextEditingController();
    final opt2Ctrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Future<void> save() async {
          if (qCtrl.text.isEmpty || opt1Ctrl.text.isEmpty || opt2Ctrl.text.isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요')));
            return;
          }
          set(() => saving = true);
          final ok = await GroupTripService.addPoll(
            groupId: groupId,
            question: qCtrl.text,
            options: [
              {'id': 'opt1', 'text': opt1Ctrl.text, 'votes': []},
              {'id': 'opt2', 'text': opt2Ctrl.text, 'votes': []},
            ],
          );
          if (!mounted) return;
          Navigator.pop(ctx);
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표가 생성됐어요')));
            await _refreshActive();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장에 실패했어요')));
          }
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('투표 만들기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 20),
                _field('질문', qCtrl, '예: 어디서 점심 먹을까요?'),
                const SizedBox(height: 12),
                _field('선택지 1', opt1Ctrl, '예: 횟집'),
                const SizedBox(height: 12),
                _field('선택지 2', opt2Ctrl, '예: 백반집'),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppColors.gray300)), child: const Text('취소', style: TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: saving ? null : save, style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('만들기', style: TextStyle(fontWeight: FontWeight.bold)))),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          // Blue gradient header — matches FE design
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: const Row(children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 13),
                        SizedBox(width: 4),
                        Text('뒤로', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('그룹 여행', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 2),
                            Text('친구들과 함께 계획하세요', style: TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showJoinSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(children: [
                              Icon(Icons.login_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('코드 참여', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.blue600))
                : _groups.isEmpty
                    ? _buildEmptyState()
                    : Column(children: [
                        _buildGroupTabs(),
                        Expanded(child: _activeGroup != null ? _buildGroupDetail(_activeGroup!) : const SizedBox()),
                      ]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text('새로운 그룹 여행을 만들어보세요', style: TextStyle(fontSize: 15, color: AppColors.gray500)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateSheet,
                icon: const Icon(Icons.add),
                label: const Text('새 그룹 만들기', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showJoinSheet,
                icon: const Icon(Icons.login_rounded),
                label: const Text('초대 코드로 참여', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.blue600, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppColors.blue600, width: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTabs() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                ..._groups.map((g) {
                  final isActive = g['id'] == _activeGroupId;
                  return GestureDetector(
                    onTap: () => setState(() => _activeGroupId = g['id'] as String),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.blue600 : AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        g['name'] as String,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.gray700),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _showCreateSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray300, width: 1.5, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('+ 새 그룹', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.gray200),
        ],
      ),
    );
  }

  Widget _buildGroupDetail(Map<String, dynamic> group) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildGroupInfo(group),
        _buildExpensesSection(group),
        _buildPollsSection(group),
      ],
    );
  }

  Widget _buildGroupInfo(Map<String, dynamic> group) {
    final members = (group['members'] as List).cast<Map<String, dynamic>>();
    final code = group['inviteCode'] as String;
    final isOwner = group['createdBy'] == GroupTripService.currentUserId;

    return Container(
      color: AppColors.blue50,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group['name'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.calendar_month_rounded, size: 13, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text('${group['startDate']} - ${group['endDate']}', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                    ]),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _copyInviteLink(code),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.share_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('초대 링크', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _copyCode(code),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.blue200), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('초대 코드  ', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                  Text(code, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.blue600, letterSpacing: 4)),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.blue600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('참여자 (${members.length}명)', style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: members.map((m) => Column(
                      children: [
                        CircleAvatar(radius: 22, backgroundImage: NetworkImage(m['avatar'] as String), backgroundColor: AppColors.gray200),
                        const SizedBox(height: 4),
                        Text(m['name'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                        if (m['isOwner'] as bool)
                          const Text('방장', style: TextStyle(fontSize: 13, color: AppColors.blue600)),
                      ],
                    )).toList(),
                  ),
                ],
              ),
              if (isOwner)
                GestureDetector(
                  onTap: () => _handleDeleteGroup(group),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text('그룹 삭제', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                    ]),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _handleLeaveGroup(group),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.logout_rounded, size: 14, color: AppColors.gray600),
                      SizedBox(width: 4),
                      Text('나가기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray600)),
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection(Map<String, dynamic> group) {
    final expenses = (group['expenses'] as List).cast<Map<String, dynamic>>();
    final members = (group['members'] as List).cast<Map<String, dynamic>>();
    final total = expenses.fold<int>(0, (s, e) => s + ((e['amount'] as int?) ?? 0));
    final perPerson = members.isNotEmpty ? (total / members.length).ceil() : 0;

    String getPaidBy(String uid) {
      if (uid == (GroupTripService.currentUserId ?? '')) return '나';
      return members.where((m) => m['id'] == uid).firstOrNull?['name'] as String? ?? '멤버';
    }

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('비용 분담', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              GestureDetector(
                onTap: () => _showAddExpenseSheet(group['id'] as String),
                child: const Text('+ 추가', style: TextStyle(fontSize: 13, color: AppColors.blue600, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _summaryBox('총 지출', '${_fmt(total)}원', AppColors.blue50, AppColors.blue600, AppColors.blue900)),
            const SizedBox(width: 10),
            Expanded(child: _summaryBox('1인당', '${_fmt(perPerson)}원', AppColors.green100, AppColors.green600, AppColors.green700)),
          ]),
          if (expenses.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...expenses.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e['description'] as String, style: const TextStyle(fontSize: 14, color: AppColors.gray700)),
                    Text('${getPaidBy(e['paid_by'] as String)} 결제', style: const TextStyle(fontSize: 13, color: AppColors.gray400)),
                  ]),
                  Text('${_fmt((e['amount'] as int?) ?? 0)}원', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                ],
              ),
            )),
          ] else ...[
            const SizedBox(height: 16),
            Center(child: Text('지출 내역을 기록해보세요', style: TextStyle(fontSize: 13, color: AppColors.gray400))),
          ],
        ],
      ),
    );
  }

  Widget _buildPollsSection(Map<String, dynamic> group) {
    final polls = (group['polls'] as List).cast<Map<String, dynamic>>();
    final me = GroupTripService.currentUserId ?? '';

    return Container(
      color: AppColors.gray50,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('투표', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              GestureDetector(
                onTap: () => _showAddPollSheet(group['id'] as String),
                child: const Text('+ 만들기', style: TextStyle(fontSize: 13, color: AppColors.blue600, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (polls.isEmpty)
            Center(child: Text('새로운 투표를 만들어보세요', style: TextStyle(fontSize: 13, color: AppColors.gray400)))
          else
            ...polls.map((poll) => _buildPollCard(poll, me, group['id'] as String)),
        ],
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll, String me, String groupId) {
    final options = (poll['options'] as List?) ?? [];
    final totalVotes = options.fold<int>(0, (s, o) => s + ((o['votes'] as List?)?.length ?? 0));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll['question'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gray900)),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final votes = List<String>.from((opt['votes'] as List?) ?? []);
            final count = votes.length;
            final pct = totalVotes > 0 ? count / totalVotes : 0.0;
            final hasVoted = votes.contains(me);

            return GestureDetector(
              onTap: () async {
                final result = await GroupTripService.vote(
                  pollId: poll['id'] as String,
                  optionId: opt['id'] as String,
                  currentOptions: options,
                );
                if (!mounted) return;
                if (result == 'already_voted') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 투표했어요')));
                } else if (result == 'ok') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표했어요')));
                  await _refreshActive();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표에 실패했어요')));
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hasVoted ? AppColors.blue600 : AppColors.gray200, width: hasVoted ? 2 : 1),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(color: AppColors.blue100, height: 40),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            if (hasVoted) const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.blue600),
                            if (hasVoted) const SizedBox(width: 4),
                            Text(opt['text'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasVoted ? AppColors.blue600 : AppColors.gray700)),
                          ]),
                          Text('${(pct * 100).round()}%  $count표', style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl, String hint, {TextInputType? type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.gray400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _summaryBox(String label, String value, Color bg, Color labelColor, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
