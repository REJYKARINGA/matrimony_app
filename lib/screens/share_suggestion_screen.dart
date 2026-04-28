import '../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ShareSuggestionScreen extends StatefulWidget {
  final int initialIndex;
  const ShareSuggestionScreen({super.key, this.initialIndex = 0});

  @override
  State<ShareSuggestionScreen> createState() => _ShareSuggestionScreenState();
}

class _ShareSuggestionScreenState extends State<ShareSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Selected category (shown as visual chips)
  String? _selectedCategory;
  bool _isSubmitting = false;
  bool _submitted = false;
  List<XFile> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  static const _categories = [
    {'label': 'New Feature',    'icon': Icons.add_circle_outline_rounded},
    {'label': 'UI Improvement', 'icon': Icons.palette_outlined},
    {'label': 'Performance',    'icon': Icons.bolt_rounded},
    {'label': 'Bug Report',     'icon': Icons.bug_report_outlined},
    {'label': 'Other',          'icon': Icons.more_horiz_rounded},
  ];

  static const _primaryColor = AppColors.deepEmerald;
  static const _deepBlue    = AppColors.deepEmerald;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final title = _titleController.text.trim();

      // Load bytes for all selected photos
      List<Map<String, dynamic>> photosData = [];
      for (var file in _selectedPhotos) {
        final bytes = await file.readAsBytes();
        photosData.add({
          'bytes': bytes,
          'fileName': file.name,
        });
      }

      final response = await ApiService.submitSuggestion(
        title,
        _selectedCategory,
        _descController.text.trim(),
        photosData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
      } else {
        final err = json.decode(response.body);
        _showError(err['message'] ?? 'Something went wrong. Please try again.');
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      _showError('Network error. Please check your connection.');
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Share a Suggestion'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _deepBlue],
              ),
            ),
          ),
          foregroundColor: AppColors.cardDark,
          elevation: 0,
          titleTextStyle: const TextStyle(color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: AppColors.cardDark),
          bottom: const TabBar(
            indicatorColor: AppColors.cardDark,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            labelColor: AppColors.cardDark,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Submit Idea'),
              Tab(text: 'My Ideas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _submitted ? _buildSuccessState() : _buildForm(),
            _buildMyIdeas(),
          ],
        ),
      ),
    );
  }

  // ─── Success State ────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_primaryColor, _deepBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.cardDark, size: 52),
            ),
            const SizedBox(height: 28),
            const Text(
              'Thank you! 🎉',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.cardDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your suggestion has been received.\nOur team reviews every idea to make the app better for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: AppColors.cardDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _submitted = false;
                _selectedCategory = null;
                _titleController.clear();
                _descController.clear();
                _selectedPhotos.clear();
              }),
              child: const Text(
                'Submit another suggestion',
                style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Form ─────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryColor, _deepBlue],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: AppColors.cardDark, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Got an idea?',
                          style: TextStyle(color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Help us build a better app.\nEvery suggestion is reviewed by our team.',
                          style: TextStyle(color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category chips
            const Text(
              'CATEGORY (OPTIONAL)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['label'];
                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 15,
                        color: isSelected ? Colors.white : AppColors.deepEmerald,
                      ),
                      const SizedBox(width: 6),
                      Text(cat['label'] as String),
                    ],
                  ),
                  onSelected: (_) => setState(() {
                    _selectedCategory = isSelected ? null : cat['label'] as String;
                  }),
                  selectedColor: AppColors.deepEmerald,
                  backgroundColor: AppColors.deepEmerald.withOpacity(0.08),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.deepEmerald,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.deepEmerald : Colors.transparent,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Title field
            _buildLabel('Feature Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                hint: 'e.g. Add dark mode to the app',
                icon: Icons.title_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),

            const SizedBox(height: 16),

            // Description field
            _buildLabel('Description (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                hint: 'Describe your idea in detail — what problem does it solve, how should it work?',
                icon: Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 16),

            // Photos section
            _buildLabel('Attach Photos (Up to 3)'),
            const SizedBox(height: 8),
            _buildPhotoPicker(),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: AppColors.cardDark,
                  disabledBackgroundColor: _primaryColor.withOpacity(0.5),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: _primaryColor.withOpacity(0.3),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.cardDark,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Submit Suggestion'),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Your suggestion will be reviewed by our developer team.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.midnightEmerald),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── My Ideas Tab ────────────────────────────────────────────────────────
  Widget _buildMyIdeas() {
    return FutureBuilder(
      future: ApiService.getMySuggestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text('Failed to load your suggestions.', style: TextStyle(color: Colors.grey.shade600)),
          );
        }

        final res = snapshot.data as dynamic;
        if (res.statusCode != 200) {
          return Center(
            child: Text('Failed to load your suggestions.', style: TextStyle(color: Colors.grey.shade600)),
          );
        }

        final data = json.decode(res.body);
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];

        if (suggestions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "You haven't submitted any ideas yet.",
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final s = suggestions[index];
            final statusStr = s['status'] ?? 'pending';

            Color statusColor;
            IconData statusIcon;
            String statusLabel;

            switch (statusStr) {
              case 'in_progress':
                statusColor = AppColors.primaryBlue;
                statusIcon = Icons.engineering_rounded;
                statusLabel = 'In Development';
                break;
              case 'completed':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle_rounded;
                statusLabel = 'Completed';
                break;
              case 'rejected':
                statusColor = Colors.red;
                statusIcon = Icons.cancel_rounded;
                statusLabel = 'Declined';
                break;
              case 'pending':
              default:
                statusColor = Colors.orange;
                statusIcon = Icons.pending_actions_rounded;
                statusLabel = 'Under Review';
                break;
            }

            final dateStr = s['created_at'];
            final dateDisplay = dateStr != null
                ? DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr))
                : '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: AppColors.divider.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (s['category'] != null && s['category'].toString().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.deepEmerald.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s['category'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepEmerald,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            Text(
                              s['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (s['description'] != null && s['description'].toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      s['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (s['user_photos'] != null && (s['user_photos'] as List).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Attached Screenshots',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.midnightEmerald),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: (s['user_photos'] as List).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, photoIndex) {
                          final photoUrl = ApiService.getImageUrl((s['user_photos'] as List)[photoIndex]);
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        child: Image.network(photoUrl, fit: BoxFit.contain),
                                      ),
                                      Positioned(
                                        top: 30, right: 20,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: AppColors.cardDark, size: 30),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photoUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60, height: 60, color: AppColors.midnightEmerald, 
                                  child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Developer notes area
                  if ((s['response_text'] != null && s['response_text'].toString().trim().isNotEmpty) || s['response_photo'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(left: const BorderSide(color: _primaryColor, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.comment_rounded, size: 12, color: _primaryColor),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Developer Response',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (s['responded_at'] != null)
                                Text(
                                  DateFormat('dd MMM hh:mm a').format(DateTime.parse(s['responded_at'])),
                                  style: TextStyle(fontSize: 10, color: _primaryColor.withOpacity(0.8)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (s['response_text'] != null && s['response_text'].toString().trim().isNotEmpty)
                            Text(
                              s['response_text'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          if (s['response_photo'] != null) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                final resPhotoUrl = ApiService.getImageUrl(s['response_photo']);
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: EdgeInsets.zero,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        InteractiveViewer(
                                          child: Image.network(resPhotoUrl, fit: BoxFit.contain),
                                        ),
                                        Positioned(
                                          top: 30, right: 20,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: AppColors.cardDark, size: 30),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ApiService.getImageUrl(s['response_photo']),
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 100, color: AppColors.midnightEmerald, 
                                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Submitted $dateDisplay',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedPhotos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_selectedPhotos.length, (index) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      // Since we are running primarily cross platform we just use future builders for web readiness, or direct memory
                      child: FutureBuilder(
                        future: _selectedPhotos[index].readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                         onTap: () => setState(() => _selectedPhotos.removeAt(index)),
                         child: Container(
                           padding: const EdgeInsets.all(2),
                           decoration: const BoxDecoration(
                             color: Colors.white70,
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(Icons.close, size: 16, color: AppColors.cardDark),
                         ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        
        if (_selectedPhotos.length < 3)
          OutlinedButton.icon(
            onPressed: () async {
               final List<XFile> images = await _picker.pickMultiImage();
               if (images.isNotEmpty) {
                 setState(() {
                    _selectedPhotos.addAll(images);
                    if (_selectedPhotos.length > 3) {
                       _selectedPhotos = _selectedPhotos.sublist(0, 3);
                       _showError("You can only attach up to 3 photos.");
                    }
                 });
               }
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add Photos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: const BorderSide(color: _primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.deepEmerald, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
















