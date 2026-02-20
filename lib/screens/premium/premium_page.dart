import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:myyearmystory/services/purchase_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Plan { monthly, yearly }

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  _Plan _selectedPlan = _Plan.yearly;
  bool _isLoading = false;
  bool _isRestoring = false;

  String? _getIntroPrice(ProductDetails? product) {
    if (product is AppStoreProductDetails) {
      final intro = product.skProduct.introductoryPrice;
      if (intro != null) return intro.price;
    }
    return null;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = context.watch<PurchaseService>();

    final monthlyProduct = purchaseService.monthlyProduct;
    final yearlyProduct = purchaseService.yearlyProduct;

    final monthlyPrice = monthlyProduct?.price ?? "";
    final yearlyPrice = yearlyProduct?.price ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF3E6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE064B4),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "My Year, My Story",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 700;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 560 : 640,
                ),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color.fromARGB(255, 226, 204, 226),
                            width: 10,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                             Text(
  tr("premium.main_phrase"),
  textAlign: TextAlign.center,
  style: GoogleFonts.monteCarlo(
  fontSize: 44,
  fontWeight: FontWeight.w600,
  height: 1.05, 
  letterSpacing: -0.5,
  color: const Color(0xFF4B3768),
),
),
                              const SizedBox(height: 10),
                              Text(
                                tr("premium.sub_phrase"),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  height: 1.35,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 44),

Container(
  height: 1,
  color: Colors.black.withOpacity(0.08),
),

const SizedBox(height: 22),

Row(
  children: [
    Expanded(
      child: _planCard(
        title: tr("premium.plan_yearly"),

        
        price: yearlyPrice,
        selected: _selectedPlan == _Plan.yearly,
        highlight: true,
        onTap: () =>
            setState(() => _selectedPlan = _Plan.yearly),
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: _planCard(
        title: tr("premium.plan_monthly"),
        price: monthlyPrice,
        selected: _selectedPlan == _Plan.monthly,
        highlight: false,
        onTap: () =>
            setState(() => _selectedPlan = _Plan.monthly),
      ),
    ),
  ],
),

const SizedBox(height: 38),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE064B4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          setState(() => _isLoading = true);
                                          if (_selectedPlan == _Plan.yearly) {
                                            await purchaseService.buyYearly();
                                          } else {
                                            await purchaseService.buyMonthly();
                                          }
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                          }
                                        },
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          tr("premium.cta_trial"),
                                          style: GoogleFonts.inter(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                tr("premium.renew_line1"),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr("premium.renew_line2"),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                color: Colors.black.withOpacity(0.08),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  TextButton(
                                    onPressed: _isRestoring
                                        ? null
                                        : () async {
                                            setState(() => _isRestoring = true);
                                            await InAppPurchase.instance
                                                .restorePurchases();
                                            if (mounted) {
                                              setState(() => _isRestoring = false);
                                            }
                                          },
                                    child: _isRestoring
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : Text(
                                            tr("premium.restore_button"),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF4B3768),
                                            ),
                                          ),
                                  ),
                                  TextButton(
                                    onPressed: () => _openUrl(
                                        "https://sonhodepapel.com/term-of-use-myms/"),
                                    child: Text(
                                      tr("premium.terms"),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF4B3768),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _openUrl(
                                        "https://sonhodepapel.com/my-year-my-story-policy/"),
                                    child: Text(
                                      tr("premium.privacy"),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF4B3768),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  tr("premium.later"),
                                  style: GoogleFonts.inter(
                                    color: Colors.black54,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _planCard({
  required String title,
  required String price,
  required bool selected,
  required bool highlight,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(
                colors: [
                  Color.fromARGB(255, 234, 205, 226),
                  Color.fromARGB(255, 217, 153, 189),
                ],
              )
            : null,
        color: highlight ? null : const Color.fromARGB(255, 176, 177, 219),
        borderRadius: BorderRadius.circular(18),
       
        border: Border.all(
          color: selected
              ? const Color.fromARGB(255, 181, 171, 209)
              : const Color.fromARGB(255, 167, 167, 170).withOpacity(0.25),
          width: selected ? 4.4 : 1,
        ),



        boxShadow: highlight
            ? [
                BoxShadow(
                  color: const Color.fromARGB(255, 159, 159, 161).withOpacity(0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                )
              ],
      ),
      child: Column(
  mainAxisAlignment: MainAxisAlignment.center,  // centraliza verticalmente
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: highlight ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 237, 231, 248),
            ),
          ),
          const SizedBox(height: 20), 
          Text(
            price,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 35,
              fontWeight: FontWeight.w800,
              color: highlight ? const Color.fromARGB(255, 250, 250, 250) : Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}

}
