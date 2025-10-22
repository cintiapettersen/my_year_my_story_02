import 'package:flutter/material.dart';

/// Classe base para todos os widgets mensais do app.
/// Fornece os parâmetros [month] e [year] para os widgets mensais.
/// Pode ser usado tanto em widgets Stateful quanto Stateless.
mixin MonthlyData {
  int get month;
  int get year;
}
