import 'package:flutter/material.dart';

class DailyInspiration extends StatelessWidget {
  const DailyInspiration({super.key});

  @override
  Widget build(BuildContext context) {
    final inspiration = _getTodaysInspiration();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink[100]!,
            Colors.purple[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inspiração de Hoje',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            inspiration['quote']!,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '- ${inspiration['author']!}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getTodaysInspiration() {
    final inspirations = [
      {
        'quote': 'Você é mais corajosa do que acredita, mais forte do que parece e mais amada do que imagina.',
        'author': 'A.A. Milne'
      },
      {
        'quote': 'O futuro pertence àqueles que acreditam na beleza de seus sonhos.',
        'author': 'Eleanor Roosevelt'
      },
      {
        'quote': 'Seja você mesma, todos os outros já existem.',
        'author': 'Oscar Wilde'
      },
      {
        'quote': 'A vida é uma aventura ousada ou não é nada.',
        'author': 'Helen Keller'
      },
      {
        'quote': 'Acredite que você pode e você já está no meio do caminho.',
        'author': 'Theodore Roosevelt'
      },
      {
        'quote': 'A única maneira impossível de realizar algo é não tentar.',
        'author': 'Sabrina Massahud'
      },
      {
        'quote': 'Você nunca é velha demais para definir outro objetivo ou sonhar um novo sonho.',
        'author': 'C.S. Lewis'
      },
      {
        'quote': 'A felicidade não é algo pronto. Ela vem de suas próprias ações.',
        'author': 'Dalai Lama'
      },
      {
        'quote': 'Seja a mudança que você quer ver no mundo.',
        'author': 'Mahatma Gandhi'
      },
      {
        'quote': 'Cada dia é uma nova oportunidade para brilhar.',
        'author': 'Anônimo'
      },
    ];
    
    // Use the day of year to get consistent daily inspiration
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final index = dayOfYear % inspirations.length;
    
    return inspirations[index];
  }
}