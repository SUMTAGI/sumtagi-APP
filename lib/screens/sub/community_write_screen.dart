import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

const _islands = ['강화도', '영흥도', '자월도', '덕적도', '백령도', '대청도', '연평도'];

class CommunityWriteScreen extends StatefulWidget {
  final String type;
  const CommunityWriteScreen({super.key, this.type = 'feed'});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String? _selectedIsland;
  XFile? _selectedImage;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _selectedImage = file);
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await CommunityService.uploadImage(_selectedImage!);
      }
      final content = _contentCtrl.text;
      await CommunityService.createPost(
        title: _titleCtrl.text.isNotEmpty
            ? _titleCtrl.text
            : content.substring(0, content.length.clamp(0, 30)),
        content: content,
        islandName: _selectedIsland,
        type: widget.type,
        imageUrl: imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('등록됐어요')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('등록에 실패했어요')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQna = widget.type == 'qna';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isQna ? '질문하기' : '리뷰 작성',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _submitting || _contentCtrl.text.isEmpty
                  ? null
                  : _submit,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                disabledBackgroundColor: AppColors.blue600.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white,
              ),
              child: Text(
                _submitting ? '등록 중...' : '등록',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.gray200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Island selector
            const Text('섬 선택',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 4),
            const Text('선택 사항',
                style: TextStyle(fontSize: 13, color: AppColors.gray400)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _islands
                  .map((island) => GestureDetector(
                        onTap: () => setState(() => _selectedIsland =
                            _selectedIsland == island ? null : island),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedIsland == island
                                ? AppColors.blue600
                                : AppColors.gray100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            island,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _selectedIsland == island
                                  ? Colors.white
                                  : AppColors.gray700,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Title
            const Text('제목',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 4),
            const Text('선택 사항',
                style: TextStyle(fontSize: 13, color: AppColors.gray400)),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    isQna ? '무엇이 궁금한가요?' : '어떤 섬을 다녀오셨나요?',
                hintStyle: const TextStyle(
                    color: AppColors.gray400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.blue600, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Row(children: [
              const Text('내용',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700)),
              const SizedBox(width: 4),
              const Text('*',
                  style: TextStyle(fontSize: 14, color: Colors.red)),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _contentCtrl,
              onChanged: (_) => setState(() {}),
              maxLines: 8,
              decoration: InputDecoration(
                hintText: isQna
                    ? '섬 여행에 대해 궁금한 점을 자유롭게 물어보세요'
                    : '다녀온 섬에 대한 솔직한 리뷰를 남겨보세요',
                hintStyle: const TextStyle(
                    color: AppColors.gray400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.blue600, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Image
            const Text('사진',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 4),
            const Text('선택 사항',
                style: TextStyle(fontSize: 13, color: AppColors.gray400)),
            const SizedBox(height: 10),
            if (_selectedImage != null) ...[
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ]),
            ] else ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(
                        color: AppColors.gray200,
                        style: BorderStyle.solid,
                        width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined,
                          size: 36, color: AppColors.gray400),
                      SizedBox(height: 8),
                      Text('사진을 추가하세요',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.gray400)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
