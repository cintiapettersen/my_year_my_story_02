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




 if (purchaseService.isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }


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
      "Produtos: ${purchaseService.products.length}",
      textAlign: TextAlign.center,
    ),


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


   if (!purchaseService.isPremium)
  Row(
    children: [
      Expanded(
        child: _planCard(
          title: tr("premium.plan_yearly"),
          price: yearlyPrice,
          selected: _selectedPlan == _Plan.yearly,
          highlight: _selectedPlan == _Plan.yearly,
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
                                  onPressed: _isLoading || purchaseService.isPremium
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
    purchaseService.isPremium
        ? "✨ Conta Premium ativa"
        : tr("premium.cta_trial"),
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
  duration: const Duration(milliseconds: 200),
  constraints: const BoxConstraints(minHeight: 130),
    decoration: BoxDecoration(
      gradient: selected
          ? const LinearGradient(
              colors: [
                Color(0xFFEACDE2),
                Color(0xFFD999BD),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: selected ? null : const Color(0xFFEAEAF4),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: selected
            ? const Color(0xFFB5ABD1)
            : Colors.transparent,
        width: selected ? 3 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: selected
              ? Colors.black.withOpacity(0.25)
              : Colors.black.withOpacity(0.05),
          blurRadius: selected ? 18 : 8,
          offset: Offset(0, selected ? 10 : 4),
        )
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
  title,
  maxLines: 2,
  textAlign: TextAlign.center,
  style: GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: selected
        ? Colors.white
        : Colors.black.withOpacity(0.7),
  ),
),
        const SizedBox(height: 16),
        const SizedBox(height: 16),

Text(
  price,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
  style: GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: selected
        ? Colors.white
        : Colors.black,
  ),
),

if (highlight) ...[
  const SizedBox(height: 6),
  Text(
    "Economize 33%",
    textAlign: TextAlign.center,
    style: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: selected
          ? Colors.white.withOpacity(0.9)
          : const Color(0xFF4B3768),
    ),
  ),
],
      ],
    ),
  ),
);
}

}
