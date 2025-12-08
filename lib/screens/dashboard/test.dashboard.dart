import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TestDashboardScreen extends StatefulWidget {
  const TestDashboardScreen({super.key});

  @override
  State<TestDashboardScreen> createState() => _TestDashboardScreenState();
}

class _TestDashboardScreenState extends State<TestDashboardScreen> {
  String userName = "Cintia PADUA";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        title: const Text("TESTE"),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🌼 FRASE TRADUZIDA
            Text(
              tr("test_screen.hello_name", namedArgs: {"name": userName}),
              style: const TextStyle(
                fontSize: 22,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 40),

            // 🔥 BOTÃO PT-BR
            ElevatedButton(
              onPressed: () async {
                await context.setLocale(const Locale('pt', 'BR'));

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TestDashboardScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text("PT-BR"),
            ),

            const SizedBox(height: 20),

            // 🔥 BOTÃO EN
            ElevatedButton(
              onPressed: () async {
                await context.setLocale(const Locale('en'));

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TestDashboardScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text("EN"),
            ),
          ],
        ),
      ),
    );
  }
}
