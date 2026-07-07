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


  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível abrir o link")),
      );
    }
  }

  String _compactPrice(String price) {
    final value = price.trim();
    if (value.isEmpty) return value;
    return value.replaceFirst(RegExp(r'([,.])00(?=[^0-9]*$)'), '');
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

	   final monthlyPrice = _compactPrice(monthlyProduct?.price ?? "");
	   final yearlyPrice = _compactPrice(yearlyProduct?.price ?? "");

	    final selectedTrialLine = _selectedPlan == _Plan.yearly
	        ? (yearlyPrice.isEmpty
	            ? tr("premium.trial_line_generic")
	            : tr(
	                "premium.trial_line_yearly",
	                args: [yearlyPrice],
	              ))
	        : (monthlyPrice.isEmpty
	            ? tr("premium.trial_line_generic")
	            : tr(
	                "premium.trial_line_monthly",
	                args: [monthlyPrice],
	              ));
   
   
   
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
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
                        vertical: 24,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          /// TÍTULO

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

                          /// PLANOS

                          if (!purchaseService.isPremium)
                            Row(
                              children: [
                                Expanded(
                                  child: _planCard(
                                    title: tr("premium.plan_yearly"),
                                    price: yearlyPrice,
                                    period: "/ano",
                                    selected: _selectedPlan == _Plan.yearly,
                                    highlight: true,
                                    onTap: () {
                                      setState(() {
                                        _selectedPlan = _Plan.yearly;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: _planCard(
                                    title: tr("premium.plan_monthly"),
                                    price: monthlyPrice,
                                    period: "/mês",
                                    selected: _selectedPlan == _Plan.monthly,
                                    highlight: false,
                                    onTap: () {
                                      setState(() {
                                        _selectedPlan = _Plan.monthly;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 38),

                          /// BOTÃO DE COMPRA

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
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

	                          const SizedBox(height: 15),

	                          Text(
	                            selectedTrialLine,
	                            textAlign: TextAlign.center,
	                            style: GoogleFonts.inter(
	                              fontSize: 12,
	                              color: Colors.black.withOpacity(0.7),
	                            ),
	                          ),

	                          const SizedBox(height: 10),

	                          Text(
	                            tr("premium.renew_line1"),
	                            textAlign: TextAlign.center,
	                            style: GoogleFonts.inter(
	                              fontSize: 12,
	                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            tr("premium.renew_line2"),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.55),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            height: 1,
                            color: Colors.black.withOpacity(0.08),
                          ),

                          const SizedBox(height: 10),

                          /// BOTÕES INFERIORES

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

                                        await purchaseService.restorePurchases();

                                        if (mounted) {
                                          setState(() => _isRestoring = false);
                                        }
                                      },
                                child: _isRestoring
                                    ? const SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
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
                                  "https://sonhodepapel.com/term-of-use-myms/",
                                ),
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
                                  "https://sonhodepapel.com/my-year-my-story-policy/",
                                ),
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
            );
          },
        ),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required String period,
    required bool selected,
    required bool highlight,
    required VoidCallback onTap,
	  }) {
	    final displayPrice = price.isEmpty ? "—" : price;

	   return GestureDetector(
	  onTap: onTap,
	  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    constraints: const BoxConstraints(minHeight: 150),
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(
      gradient: selected
          ? const LinearGradient(
              colors: [
                Color(0xFFE59BC4),
                Color(0xFFD66AA6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: selected ? null : const Color(0xFFEAEAF4),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: selected
            ? const Color(0xFFB5ABD1)
            : Colors.transparent,
        width: selected ? 3 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(selected ? 0.15 : 0.05),
          blurRadius: selected ? 12 : 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        /// TÍTULO DO PLANO
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : const Color(0xFF4B3768),
          ),
        ),

        const SizedBox(height: 8),

	        /// PREÇO
	        FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    displayPrice,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: selected ? Colors.white : Colors.black,
    ),
  ),
),

        const SizedBox(height: 4
        ),

        /// PERÍODO
        Text(
          period,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: selected
                ? Colors.white.withOpacity(0.9)
                : Colors.black.withOpacity(0.6),
          ),
        ),

        const SizedBox(height: 8),

		        /// ÁREA RESERVADA PARA "MELHOR VALOR"
			        ConstrainedBox(
			          constraints: const BoxConstraints(minHeight: 44),
		          child: highlight
	              ? Column(
	                  children: [

		                    Text(
		                      "premium.best_value".tr(),
		                      textAlign: TextAlign.center,
		                      maxLines: 1,
		                      softWrap: false,
		                      overflow: TextOverflow.ellipsis,
		                      style: GoogleFonts.inter(
		                        fontSize: 11,
		                        fontWeight: FontWeight.w600,
		                        color: selected
		                            ? Colors.white
                            : const Color(0xFF4B3768),
                      ),
                    ),

                    const SizedBox(height: 2),

		                    Text(
		                      "premium.save_33".tr(),
		                      textAlign: TextAlign.center,
		                      maxLines: 1,
		                      softWrap: false,
		                      overflow: TextOverflow.ellipsis,
		                      style: GoogleFonts.inter(
		                        fontSize: 10,
		                        fontWeight: FontWeight.w500,
		                        color: selected
		                            ? Colors.white.withOpacity(0.9)
		                            : const Color(0xFF4B3768),
		                      ),
                    ),
	                  ],
	                )
	              : Column(
	                  children: [
		                    Text(
		                      "premium.monthly_note_1".tr(),
		                      textAlign: TextAlign.center,
		                      maxLines: 1,
		                      softWrap: false,
		                      overflow: TextOverflow.ellipsis,
		                      style: GoogleFonts.inter(
		                        fontSize: 11,
		                        fontWeight: FontWeight.w600,
		                        color: selected
		                            ? Colors.white.withOpacity(0.95)
	                            : const Color(0xFF4B3768),
	                      ),
	                    ),
	                    const SizedBox(height: 2),
				                    Text(
				                      "premium.monthly_note_2".tr(),
				                      textAlign: TextAlign.center,
				                      softWrap: true,
				                      style: GoogleFonts.inter(
				                        fontSize: 11,
			                        fontWeight: FontWeight.w500,
			                        color: selected
		                            ? Colors.white.withOpacity(0.9)
	                            : const Color(0xFF4B3768),
	                      ),
	                    ),
	                  ],
	                ),
	        ),
	      ],
	    ),
	  ),
);
}}
