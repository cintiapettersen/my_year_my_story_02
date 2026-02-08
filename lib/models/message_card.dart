import 'message_category.dart';




class MessageCard {
  /// ID da mensagem no banco (null para gemini/fallback)
  final String? id;

  /// Tipo da mensagem
  final MessageType type;

  /// Texto exibido
  final String text;

  /// Data de referência (opcional)
  final DateTime? referenceDate;

  /// true quando foi gerada como fallback
  final bool isFallback;

  /// origem: gemini | database | fallback
  final String? source;

  MessageCard({
    this.id, // 👈 agora opcional
    required this.type,
    required this.text,
    this.referenceDate,
    this.isFallback = false,
    this.source,
  });

  /// Factory para fallback
  factory MessageCard.fallback({
    required MessageType type,
    required String textKey,
  }) {
    return MessageCard(
      id: null,
      type: type,
      text: textKey, // chave i18n
      isFallback: true,
      source: 'fallback',
    );
  }
}
