// Classe que representa um supermercado cadastrado.
// Permite armazenar o nome do mercado para depois gerar relatórios de histórico.
class Supermercado {
  // ID gerado automaticamente no SQLite.
  final int? id;

  // Nome do supermercado.
  final String nome;

  // Construtor.
  Supermercado({this.id, required this.nome});

  // Converte em mapa para persistência no banco.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  // Cria um objeto a partir do banco.
  factory Supermercado.fromMap(Map<String, dynamic> map) {
    return Supermercado(
      id: map['id'] as int?,
      nome: map['nome'] as String,
    );
  }
}
