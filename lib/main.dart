// Este é o arquivo principal do app.
// Ele inicializa o Flutter, cria a tela principal e chama o banco de dados.
// Em termos simples: aqui definimos "o que aparecerá na tela" e "como o app reage".

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database/app_database.dart';
import 'models/categoria.dart';
import 'models/compra.dart';
import 'models/supermercado.dart';

// Função principal do app.
// É a primeira coisa que o Flutter executa.
void main() async {
  // Garante que o Flutter esteja pronto para rodar antes de iniciar o app.
  WidgetsFlutterBinding.ensureInitialized();

  // Cria uma instância do banco e inicializa a conexão.
  final database = AppDatabase();
  await database.database;

  // Inicia a aplicação com a tela inicial.
  runApp(AppComprasApp(database: database));
}

// Esta classe representa a raiz do app.
// Ela define o tema visual e a página inicial.
class AppComprasApp extends StatelessWidget {
  final AppDatabase database;

  const AppComprasApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Compras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: HomePage(database: database),
    );
  }
}

// Página principal do app.
// Aqui o usuário vai ver as compras, o total gasto e poderá adicionar itens.
class HomePage extends StatefulWidget {
  final AppDatabase database;

  const HomePage({super.key, required this.database});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Estado da tela principal.
class _HomePageState extends State<HomePage> {
  // Lista de compras que vão aparecer na tela.
  List<Compra> _compras = [];

  // Lista de categorias existentes.
  List<Categoria> _categorias = [];

  // Lista de supermercados cadastrados.
  List<Supermercado> _supermercados = [];

  // Controle para mostrar carregamento enquanto busca os dados.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Quando a tela abrir, busca os dados do banco.
    _carregarDados();
  }

  // Busca todas as categorias, supermercados e compras do SQLite.
  Future<void> _carregarDados() async {
    final categorias = await widget.database.getCategorias();
    final supermercados = await widget.database.getSupermercados();
    final compras = await widget.database.getCompras();

    // Atualiza o estado para renderizar a tela com os dados carregados.
    setState(() {
      _categorias = categorias;
      _supermercados = supermercados;
      _compras = compras;
      _isLoading = false;
    });
  }

  // Abre um popup para cadastrar uma nova compra.
  Future<void> _adicionarCompra() async {
    // Controladores dos campos do formulário.
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final precoController = TextEditingController();
    final unidadeController = TextEditingController(text: 'kg');

    // Valores iniciais para os dropdowns.
    Categoria? categoriaSelecionada = _categorias.isNotEmpty ? _categorias.first : null;
    Supermercado? supermercadoSelecionado =
        _supermercados.isNotEmpty ? _supermercados.first : null;

    // showDialog cria uma janela modal estilo popup.
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nova compra'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo do nome do produto.
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Produto'),
                    ),
                    const SizedBox(height: 12),

                    // Linha com quantidade e unidade.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantidadeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Quantidade'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unidadeController,
                            decoration: const InputDecoration(labelText: 'Unidade'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Campo do preço pago.
                    TextField(
                      controller: precoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Preço pago'),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown de categoria.
                    DropdownButtonFormField<Categoria>(
                      value: categoriaSelecionada,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: _categorias
                          .map(
                            (categoria) => DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria.nome),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        categoriaSelecionada = value;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Dropdown de supermercado.
                    DropdownButtonFormField<Supermercado>(
                      value: supermercadoSelecionado,
                      decoration: const InputDecoration(labelText: 'Supermercado'),
                      items: _supermercados
                          .map(
                            (supermercado) => DropdownMenuItem(
                              value: supermercado,
                              child: Text(supermercado.nome),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        supermercadoSelecionado = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                // Botão cancelar.
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),

                // Botão salvar.
                FilledButton(
                  onPressed: () async {
                    // Valida se todos os dados foram preenchidos.
                    if (nomeController.text.trim().isEmpty ||
                        categoriaSelecionada == null ||
                        supermercadoSelecionado == null ||
                        quantidadeController.text.trim().isEmpty ||
                        precoController.text.trim().isEmpty) {
                      return;
                    }

                    // Cria o objeto Compra com os dados digitados.
                    final novaCompra = Compra(
                      nome: nomeController.text.trim(),
                      categoriaId: categoriaSelecionada!.id!,
                      categoriaNome: categoriaSelecionada!.nome,
                      unidade: unidadeController.text.trim().isEmpty ? 'un' : unidadeController.text.trim(),
                      quantidade: double.tryParse(quantidadeController.text.replaceAll(',', '.')) ?? 0,
                      preco: double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0,
                      supermercadoId: supermercadoSelecionado!.id!,
                      supermercadoNome: supermercadoSelecionado!.nome,
                      // Guarda a data atual no momento da compra.
                      dataCompra: DateTime.now(),
                    );

                    // Salva a compra no banco.
                    await widget.database.insertCompra(novaCompra);

                    // Fecha o popup após salvar.
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    // Se o popup voltou com sucesso, recarrega a tela para mostrar a nova compra.
    if (result == true) {
      _carregarDados();
    }
  }

  // Método usado para cadastrar categoria ou supermercado.
  // A lógica é a mesma para ambos; apenas muda o texto e a tabela que será salva.
  Future<void> _adicionarCategoriaOuSupermercado(String tipo) async {
    final controller = TextEditingController();

    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tipo == 'categoria' ? 'Nova categoria' : 'Novo supermercado'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: tipo == 'categoria' ? 'Nome da categoria' : 'Nome do supermercado',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (nome == null || nome.isEmpty) {
      return;
    }

    // Salva de acordo com o tipo recebido.
    if (tipo == 'categoria') {
      await widget.database.insertCategoria(nome);
    } else {
      await widget.database.insertSupermercado(nome);
    }

    _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    // Soma o total gasto com base nas compras carregadas.
    final totalGasto = _compras.fold<double>(0, (valor, compra) => valor + compra.preco);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Compras'),
        actions: [
          // Botão para adicionar categoria.
          IconButton(
            tooltip: 'Nova categoria',
            onPressed: () => _adicionarCategoriaOuSupermercado('categoria'),
            icon: const Icon(Icons.category),
          ),

          // Botão para adicionar supermercado.
          IconButton(
            tooltip: 'Novo supermercado',
            onPressed: () => _adicionarCategoriaOuSupermercado('supermercado'),
            icon: const Icon(Icons.store),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Card com o total gasto.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total gasto',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'R\$ ${totalGasto.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista das compras registradas.
                  Expanded(
                    child: _compras.isEmpty
                        ? const Center(
                            child: Text('Nenhuma compra registrada ainda.'),
                          )
                        : ListView.builder(
                            itemCount: _compras.length,
                            itemBuilder: (context, index) {
                              final compra = _compras[index];
                              final dataFormatada = DateFormat('dd/MM/yyyy').format(compra.dataCompra);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(compra.nome),
                                  subtitle: Text(
                                    '${compra.categoriaNome} • ${compra.quantidade} ${compra.unidade} • ${compra.supermercadoNome}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'R\$ ${compra.preco.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(dataFormatada),
                                    ],
                                  ),
                                  // Segurar pressionado na compra exclui o registro.
                                  onLongPress: () async {
                                    await widget.database.deleteCompra(compra.id!);
                                    _carregarDados();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarCompra,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Compra'),
      ),
    );
  }
}
