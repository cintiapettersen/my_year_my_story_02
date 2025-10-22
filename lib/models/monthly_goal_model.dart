class MonthlyGoal {
  final String id;
  final String userId;
  final int mes;          // corresponde a "mes" no banco
  final int ano;          // corresponde a "ano" no banco
  final String conteudo;  // corresponde a "conteudo" no banco
  final bool concluido;   // corresponde a "concluido" no banco
  final DateTime createdAt;

  MonthlyGoal({
    required this.id,
    required this.userId,
    required this.mes,
    required this.ano,
    required this.conteudo,
    required this.concluido,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mes': mes,
      'ano': ano,
      'conteudo': conteudo,
      'concluida': concluido,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MonthlyGoal.fromJson(Map<String, dynamic> json) {
    return MonthlyGoal(
      id: json['id'],
      userId: json['user_id'],
      mes: json['mes'],
      ano: json['ano'],
      conteudo: json['conteudo'],
      concluido: json['concluida'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  MonthlyGoal copyWith({
    String? id,
    String? userId,
    int? mes,
    int? ano,
    String? conteudo,
    bool? concluido,
    DateTime? createdAt,
  }) {
    return MonthlyGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      conteudo: conteudo ?? this.conteudo,
      concluido: concluido ?? this.concluido,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
