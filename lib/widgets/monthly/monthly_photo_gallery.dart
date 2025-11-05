import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:my_year_my_story/widgets/shared/month_page_template.dart';

class MonthlyPhotoGallery extends StatefulWidget {
  final int month;
  final int year;

  const MonthlyPhotoGallery({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<MonthlyPhotoGallery> createState() => _MonthlyPhotoGalleryState();
}

class _MonthlyPhotoGalleryState extends State<MonthlyPhotoGallery>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override

  void initState() {
    super.initState();
    _photos = []; // começa vazio
    _isLoading = false;
  }


  // ================== POPUP “DISPONÍVEL EM BREVE” ==================
  Future<void> _showComingSoonDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('photos_popup_title'.tr()),
        content: Text(
          'photos_popup_content'.tr(),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok_button'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: 'photos_title'.tr(),
      description: 'photos_description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_photos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    const Icon(Icons.photo_camera_outlined,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'photos_empty'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index < _photos.length) {
                  final photo = _photos[index];
                  final url = photo['signed_url'] as String?;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: url != null
                        ? (url.startsWith('assets/')
                        ? Image.asset(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                        : Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ))
                        : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 40),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: _showComingSoonDialog,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                        border: Border.all(
                            color: Colors.grey[400]!, width: 1),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.grey, size: 40),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
