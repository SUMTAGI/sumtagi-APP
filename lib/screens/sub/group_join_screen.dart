import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/group_trip_service.dart';
import '../../theme/app_colors.dart';

class GroupJoinScreen extends StatefulWidget {
  final String code;
  const GroupJoinScreen({super.key, required this.code});
  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  Map<String, dynamic>? _group;
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await GroupTripService.getGroupByInviteCode(widget.code);
    if (!mounted) return;
    setState(() { _group = data; _loading = false; });
  }

  Future<void> _join() async {
    if (_group == null) return;
    setState(() => _joining = true);
    final ok = await GroupTripService.joinGroup(_group!['id'] as String);
    if (!mounted) return;
    setState(() => _joining = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('참여에 실패했어요. 다시 시도해주세요')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_group!['name']} 그룹에 참여했어요!')));
    context.go('/group-trip');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        title: const Text('그룹 초대', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue600))
          : _group == null
              ? _buildNotFound()
              : _buildGroupPreview(),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_off_outlined, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text('초대 링크를 찾을 수 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray700)),
            const SizedBox(height: 8),
            const Text('링크가 만료됐거나 잘못된 코드예요', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/group-trip'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('그룹 여행으로 가기', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupPreview() {
    final group = _group!;
    final members = (group['members'] as List).cast<Map<String, dynamic>>();
    final dest = (group['destination'] as List).cast<String>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.group_rounded, size: 40, color: AppColors.blue600),
          ),
          const SizedBox(height: 16),
          const Text('그룹 여행 초대', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 6),
          Text(group['name'] as String, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.gray900), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _infoRow(Icons.location_on_rounded, dest.join(', ')),
                const SizedBox(height: 12),
                _infoRow(Icons.calendar_month_rounded, '${group['startDate']} - ${group['endDate']}'),
                const SizedBox(height: 12),
                _infoRow(Icons.people_rounded, '현재 참여자 ${members.length}명'),
              ],
            ),
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...members.take(5).map((m) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(radius: 20, backgroundImage: NetworkImage(m['avatar'] as String), backgroundColor: AppColors.gray200),
                )),
                if (members.length > 5)
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.gray200,
                    child: Text('+${members.length - 5}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray600)),
                  ),
              ],
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _joining ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _joining
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('그룹 참여하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.blue500),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.gray700))),
    ]);
  }
}
