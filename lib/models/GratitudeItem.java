class GratitudeItem {
  final int id;
  final String conteudo;
  final DateTime data;

  GratitudeItem({
    required this.id,
    required this.conteudo,
    required this.data,
  });

  factory GratitudeItem.fromMap(Map<String, dynamic> map) {
    return GratitudeItem(
      id: map['id'],
      conteudo: map['conteudo'],
      data: DateTime.parse(map['data']),
    );
  }
}
