// Classe que representa uma categoria de produto.
// Exemplo: Frutas, Higiene, Limpeza, Bebidas, etc.
class Categoria {
  // ID da categoria no banco. Pode ser nulo antes de salvar.
  final int? id;

  // Nome da categoria.
  final String nome;

  // Construtor da categoria.
  Categoria({this.id, required this.nome});

  // Converte a categoria em um mapa para salvar no SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  // Cria uma Categoria a partir dos dados vindos do banco.
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as int?,
      nome: map['nome'] as String,
    );
  }
}
