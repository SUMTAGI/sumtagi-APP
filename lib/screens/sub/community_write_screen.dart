import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

const _islands = ['강화도', '영흥도', '자월도', '덕적도', '백령도', '대청도', '연평도'];
const _maxImages = 5;

class CommunityWriteScreen extends StatefulWidget {
  final String type;
  final String? editId;
  const CommunityWriteScreen({super.key, this.type = 'feed', this.editId});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String? _selectedIsland;
  final List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _submitting = false;
  bool _loadingPost = false;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadPost();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() => _loadingPost = true);
    final post = await CommunityService.getPost(widget.editId!);
    if (post != null && mounted) {
      _titleCtrl.text = post['title'] as String? ?? '';
      _contentCtrl.text = post['content'] as String? ?? '';
      _selectedIsland = post['island_name'] as String?;
      final images = post['images'];
      if (images is List && images.isNotEmpty) {
        _existingImageUrls = images.whereType<String>().toList();
      } else if (post['image_url'] is String) {
        _existingImageUrls = [post['image_url'] as String];
      }
    }
    if (mounted) setState(() => _loadingPost = false);
  }

  int get _imageCount => _existingImageUrls.length + _newImages.length;

  Future<void> _pickImages() async {
    final remaining = _maxImages - _imageCount;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty) return;
    setState(() => _newImages.addAll(files.take(remaining)));
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final uploaded = _newImages.isNotEmpty
          ? await CommunityService.uploadImages(_newImages)
          : <String>[];
      final images = [..._existingImageUrls, ...uploaded];
      final content = _contentCtrl.text;
      final title = _titleCtrl.text.isNotEmpty
          ? _titleCtrl.text
          : content.substring(0, content.length.clamp(0, 30));
      if (_isEdit) {
        await CommunityService.updatePost(
          postId: widget.editId!,
          title: title,
          content: content,
          islandName: _selectedIsland,
          images: images,
        );
      } else {
        await CommunityService.createPost(
          title: title,
          content: content,
          islandName: _selectedIsland,
          type: widget.type,
          images: images,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? '수정됐어요' : '등록됐어요')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? '수정에 실패했어요' : '등록에 실패했어요')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQna = widget.type == 'qna';
    final headerTitle =
        _isEdit ? (isQna ? '질문 수정' : '리뷰 수정') : (isQna ? '질문하기' : '리뷰 작성');
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
          headerTitle,
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
                _submitting ? '등록 중...' : (_isEdit ? '수정' : '등록'),
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
      body: _loadingPost
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

            // Images
            Row(children: [
              const Text('사진',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700)),
              const SizedBox(width: 6),
              Text('$_imageCount/$_maxImages',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray400)),
            ]),
            const SizedBox(height: 4),
            const Text('선택 사항',
                style: TextStyle(fontSize: 13, color: AppColors.gray400)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._existingImageUrls.asMap().entries.map((e) => _ImageThumb(
                      child: Image.network(e.value,
                          width: 96, height: 96, fit: BoxFit.cover),
                      onRemove: () => setState(
                          () => _existingImageUrls.removeAt(e.key)),
                    )),
                ..._newImages.asMap().entries.map((e) => _ImageThumb(
                      child: Image.file(File(e.value.path),
                          width: 96, height: 96, fit: BoxFit.cover),
                      onRemove: () =>
                          setState(() => _newImages.removeAt(e.key)),
                    )),
                if (_imageCount < _maxImages)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(
                            color: AppColors.gray200,
                            style: BorderStyle.solid,
                            width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          size: 28, color: AppColors.gray400),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _ImageThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
      Positioned(
        top: 4,
        right: 4,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            decoration: const BoxDecoration(
                color: Colors.black54, shape: BoxShape.circle),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ),
    ]);
  }
}
