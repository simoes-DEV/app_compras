// Teste simples do cálculo do valor total de uma compra.
import 'package:flutter_test/flutter_test.dart';

import 'package:app_compras/models/compra.dart';

void main() {
  test('multiplica a quantidade pelo preco unitario', () {
    final compra = Compra(
      nome: 'Arroz Tio Joao 1 kg',
      categoriaId: 1,
      categoriaNome: 'Alimentos',
      unidade: 'un',
      quantidade: 2,
      precoUnitario: 8.90,
      supermercadoId: 1,
      sessaoId: 1,
      supermercadoNome: 'Mercado Familia',
      dataCompra: DateTime(2026, 11, 15),
    );

    expect(compra.preco, closeTo(17.80, 0.001));
    expect(compra.toMap()['preco'], closeTo(17.80, 0.001));
  });
}
