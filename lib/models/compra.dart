// Classe que representa uma compra no app.
// Ela guarda os dados que interessam para o histórico: produto, preço,
// categoria, supermercado, quantidade e data da compra.
class Compra {
  // id pode ser nulo porque no banco o valor é gerado automaticamente.
  final int? id;

  // Nome do produto comprado, por exemplo: "banana" ou "leite".
  final String nome;

  // ID da categoria associada ao produto.
  final int categoriaId;

  // Nome da categoria para facilitar a exibição na tela.
  final String categoriaNome;

  // Unidade de medida: kg, unidade, pacote, litro, etc.
  final String unidade;

  // Quantidade comprada.
  final double quantidade;

  // Preço de uma unidade, usado para calcular o total e consultar o histórico.
  final double precoUnitario;

  // ID do supermercado em que aconteceu a compra.
  final int supermercadoId;

  // Número automático da visita ao supermercado em que o item foi comprado.
  final int sessaoId;

  // Nome do supermercado para mostrar em listas e relatórios.
  final String supermercadoNome;

  // Data e hora em que a compra foi registrada.
  final DateTime dataCompra;

  // Calcula o valor total com base na quantidade e no preço de cada unidade.
  double get preco => quantidade * precoUnitario;

  // Indica se o item foi deixado em standby (aguardando pesagem/valor no caixa).
  bool get aguardandoPesagem => quantidade <= 0 || precoUnitario <= 0;

  // Construtor da classe.
  // Os campos obrigatórios são definidos com "required".
  Compra({
    this.id,
    required this.nome,
    required this.categoriaId,
    required this.categoriaNome,
    required this.unidade,
    required this.quantidade,
    required this.precoUnitario,
    required this.supermercadoId,
    required this.sessaoId,
    required this.supermercadoNome,
    required this.dataCompra,
  });

  // Converte o objeto em um mapa JSON-like para salvar no SQLite.
  // SQLite aceita mapas com chaves e valores.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria_id': categoriaId,
      'unidade': unidade,
      'quantidade': quantidade,
      'preco': preco,
      'preco_unitario': precoUnitario,
      'supermercado_id': supermercadoId,
      'sessao_id': sessaoId,
      // O SQLite salva data como texto em ISO 8601.
      'data_compra': dataCompra.toIso8601String(),
    };
  }

  // Cria um objeto Compra a partir de um mapa vindo do banco.
  // Isso é útil quando fazemos consulta ao SQLite.
  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      categoriaId: map['categoria_id'] as int,
      categoriaNome: map['categoria_nome'] ?? '',
      unidade: map['unidade'] as String,
      quantidade: (map['quantidade'] as num).toDouble(),
      precoUnitario: (map['preco_unitario'] as num).toDouble(),
      supermercadoId: map['supermercado_id'] as int,
      sessaoId: map['sessao_id'] as int,
      supermercadoNome: map['supermercado_nome'] ?? '',
      dataCompra: DateTime.parse(map['data_compra'] as String),
    );
  }
}
