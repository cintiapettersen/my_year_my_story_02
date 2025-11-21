import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

Future<void> showPremiumPopup(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) {
      return Stack(
        children: [
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            backgroundColor: const Color(0xFFFFF1F6),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 42,
                  color: Color(0xFFB03062),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Vem ser Premium",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB03062),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 14),

                const Text(
                  "Com o plano Premium, você desbloqueia todas as funções do app e pode salvar quantas memórias quiser! ✨",
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 26),

                // ⭐ BOTÃO ÚNICO — CENTRALIZADO E LINDO
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // 👉 Coloque aqui pra onde deve ir a página premium
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCD4B78),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Conhecer Premium",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ❌ Botão de fechar no canto superior direito
          Positioned(
            right: 6,
            top: 6,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      );
    },
  );
}
