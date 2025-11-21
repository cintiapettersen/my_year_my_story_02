import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/label_colors.dart';
import 'package:easy_localization/easy_localization.dart';

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

    // MOCK para testes — quando integrar Supabase, troca por fetch real.
    _photos = [];

    _isLoading = false;
  }

  // ================== POPUP FOFO "EM BREVE" ==================
  Future<void> showComingSoonPopup(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7FA),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🌸 Icone cute
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECF3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFC03B66),
                      size: 42,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    "photos.popup_title".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFFC03B66),
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "photos.popup_content".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: 28),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 36,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC03B66),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC03B66).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        "photos.ok_button".tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================== LAYOUT ==================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MonthPageTemplate(
      title: "",
      month: widget.month,
      year: widget.year,
      pageLabel: "photos.title".tr(),
      labelColor: const Color(0xFFb71691),
      description: "photos.description".tr(),

      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                          "photos.empty".tr(),
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
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),

                  itemBuilder: (context, index) {
                    if (index < _photos.length) {
                      final photo = _photos[index];
                      final url = photo['signed_url'] as String?;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: url != null
                            ? (url.startsWith("assets/")
                                ? Image.asset(url, fit: BoxFit.cover)
                                : Image.network(url, fit: BoxFit.cover))
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () => showComingSoonPopup(context),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFFFE8F1), // 🌸 Fundo rosinha
                            border: Border.all(
                              color: const Color.fromARGB(255, 158, 118, 135), // 🌸 Borda rosinha suave
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 42,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }
}
