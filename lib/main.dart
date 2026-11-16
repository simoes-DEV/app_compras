// Este é o arquivo principal do app.
// Ele inicializa o Flutter, cria a tela principal e chama o banco de dados.
// Em termos simples: aqui definimos "o que aparecerá na tela" e "como o app reage".

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'database/app_database.dart';
import 'models/categoria.dart';
import 'models/compra.dart';
import 'models/supermercado.dart';

// Transforma cada caractere digitado no nome do produto em maiúscula.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

// Formata números digitados estilo "maquininha de cartão" (ex: 599 -> 5,99).
// Assim o usuário só digita números sem precisar procurar a vírgula.
class CentavosInputFormatter extends TextInputFormatter {
  const CentavosInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final apenasDigitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (apenasDigitos.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final valorCentavos = int.tryParse(apenasDigitos) ?? 0;
    if (valorCentavos == 0) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final valorReais = valorCentavos / 100.0;
    final textoFormatado = valorReais.toStringAsFixed(2).replaceAll('.', ',');

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}

// Representa um item de atalho rápido (do histórico do usuário ou do catálogo padrão).
class ProdutoAtalho {
  final String nome;
  final String categoriaNome;
  final String unidade;
  final double? ultimoPrecoUnitario;
  final String? ultimoSupermercado;
  final int vezesComprado;

  const ProdutoAtalho({
    required this.nome,
    required this.categoriaNome,
    required this.unidade,
    this.ultimoPrecoUnitario,
    this.ultimoSupermercado,
    this.vezesComprado = 0,
  });
}

// Catálogo base para o usuário já começar escolhendo com 1 toque sem precisar digitar.
const List<ProdutoAtalho> kCatalogoRapidoPadrao = [
  // Alimentos
  ProdutoAtalho(nome: 'ARROZ 1KG', categoriaNome: 'Alimentos', unidade: 'pacote'),
  ProdutoAtalho(nome: 'FEIJÃO 1KG', categoriaNome: 'Alimentos', unidade: 'pacote'),
  ProdutoAtalho(nome: 'CAFÉ', categoriaNome: 'Alimentos', unidade: 'pacote'),
  ProdutoAtalho(nome: 'AÇÚCAR', categoriaNome: 'Alimentos', unidade: 'kg'),
  ProdutoAtalho(nome: 'ÓLEO DE SOJA', categoriaNome: 'Alimentos', unidade: 'un'),
  ProdutoAtalho(nome: 'MACARRÃO', categoriaNome: 'Alimentos', unidade: 'pacote'),
  ProdutoAtalho(nome: 'MOLHO DE TOMATE', categoriaNome: 'Alimentos', unidade: 'un'),
  ProdutoAtalho(nome: 'SAL', categoriaNome: 'Alimentos', unidade: 'kg'),
  ProdutoAtalho(nome: 'FARINHA DE TRIGO', categoriaNome: 'Alimentos', unidade: 'kg'),
  ProdutoAtalho(nome: 'BISCOITO', categoriaNome: 'Alimentos', unidade: 'pacote'),
  // Laticínios e Padaria
  ProdutoAtalho(nome: 'LEITE', categoriaNome: 'Laticínios e Padaria', unidade: 'L'),
  ProdutoAtalho(nome: 'PÃO FRANCÊS', categoriaNome: 'Laticínios e Padaria', unidade: 'kg'),
  ProdutoAtalho(nome: 'PÃO DE FORMA', categoriaNome: 'Laticínios e Padaria', unidade: 'pacote'),
  ProdutoAtalho(nome: 'MANTEIGA', categoriaNome: 'Laticínios e Padaria', unidade: 'un'),
  ProdutoAtalho(nome: 'QUEIJO MUSSARELA', categoriaNome: 'Laticínios e Padaria', unidade: 'kg'),
  ProdutoAtalho(nome: 'PRESUNTO', categoriaNome: 'Laticínios e Padaria', unidade: 'kg'),
  ProdutoAtalho(nome: 'IOGURTE', categoriaNome: 'Laticínios e Padaria', unidade: 'un'),
  ProdutoAtalho(nome: 'OVOS DÚZIA', categoriaNome: 'Laticínios e Padaria', unidade: 'un'),
  // Hortifruti
  ProdutoAtalho(nome: 'BANANA', categoriaNome: 'Hortifruti', unidade: 'kg'),
  ProdutoAtalho(nome: 'TOMATE', categoriaNome: 'Hortifruti', unidade: 'kg'),
  ProdutoAtalho(nome: 'CEBOLA', categoriaNome: 'Hortifruti', unidade: 'kg'),
  ProdutoAtalho(nome: 'BATATA', categoriaNome: 'Hortifruti', unidade: 'kg'),
  ProdutoAtalho(nome: 'MAÇÃ', categoriaNome: 'Hortifruti', unidade: 'kg'),
  ProdutoAtalho(nome: 'ALHO', categoriaNome: 'Hortifruti', unidade: 'kg'),
  ProdutoAtalho(nome: 'ALFACE', categoriaNome: 'Hortifruti', unidade: 'un'),
  ProdutoAtalho(nome: 'CENOURA', categoriaNome: 'Hortifruti', unidade: 'kg'),
  // Carnes e Frios
  ProdutoAtalho(nome: 'PEITO DE FRANGO', categoriaNome: 'Carnes e Frios', unidade: 'kg'),
  ProdutoAtalho(nome: 'FRANGO INTEIRO', categoriaNome: 'Carnes e Frios', unidade: 'kg'),
  ProdutoAtalho(nome: 'CARNE MOÍDA', categoriaNome: 'Carnes e Frios', unidade: 'kg'),
  ProdutoAtalho(nome: 'CARNE BOVINA', categoriaNome: 'Carnes e Frios', unidade: 'kg'),
  ProdutoAtalho(nome: 'LINGUIÇA', categoriaNome: 'Carnes e Frios', unidade: 'kg'),
  // Bebidas
  ProdutoAtalho(nome: 'REFRIGERANTE 2L', categoriaNome: 'Bebidas', unidade: 'un'),
  ProdutoAtalho(nome: 'ÁGUA MINERAL', categoriaNome: 'Bebidas', unidade: 'un'),
  ProdutoAtalho(nome: 'SUCO', categoriaNome: 'Bebidas', unidade: 'L'),
  ProdutoAtalho(nome: 'CERVEJA LATA', categoriaNome: 'Bebidas', unidade: 'un'),
  // Limpeza
  ProdutoAtalho(nome: 'DETERGENTE', categoriaNome: 'Limpeza', unidade: 'un'),
  ProdutoAtalho(nome: 'SABÃO EM PÓ', categoriaNome: 'Limpeza', unidade: 'pacote'),
  ProdutoAtalho(nome: 'ÁGUA SANITÁRIA', categoriaNome: 'Limpeza', unidade: 'L'),
  ProdutoAtalho(nome: 'AMACIANTE', categoriaNome: 'Limpeza', unidade: 'L'),
  ProdutoAtalho(nome: 'DESINFETANTE', categoriaNome: 'Limpeza', unidade: 'L'),
  ProdutoAtalho(nome: 'ESPONJA DE LOUÇA', categoriaNome: 'Limpeza', unidade: 'pacote'),
  // Higiene
  ProdutoAtalho(nome: 'PAPEL HIGIÊNICO', categoriaNome: 'Higiene', unidade: 'pacote'),
  ProdutoAtalho(nome: 'CREME DENTAL', categoriaNome: 'Higiene', unidade: 'un'),
  ProdutoAtalho(nome: 'SABONETE', categoriaNome: 'Higiene', unidade: 'un'),
  ProdutoAtalho(nome: 'SHAMPOO', categoriaNome: 'Higiene', unidade: 'un'),
  ProdutoAtalho(nome: 'DESODORANTE', categoriaNome: 'Higiene', unidade: 'un'),
];

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

  // Supermercado selecionado para a compra em andamento.
  Supermercado? _supermercadoAtual;

  // Número da visita atual; null significa que ainda não há item salvo nela.
  int? _sessaoAtualId;

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
    final sessaoAberta = await widget.database.getSessaoAberta();
    Supermercado? supermercadoDaSessao;

    if (sessaoAberta != null) {
      final supermercadoId = sessaoAberta['supermercado_id'] as int;
      for (final supermercado in supermercados) {
        if (supermercado.id == supermercadoId) {
          supermercadoDaSessao = supermercado;
          break;
        }
      }
    }

    // Atualiza o estado para renderizar a tela com os dados carregados.
    setState(() {
      _categorias = categorias;
      _supermercados = supermercados;
      _compras = compras;
      _sessaoAtualId = sessaoAberta?['id'] as int?;
      _supermercadoAtual = supermercadoDaSessao;
      _isLoading = false;
    });
  }

  // Mostra a lista de supermercados para iniciar ou trocar o local da compra.
  Future<Supermercado?> _escolherSupermercado() async {
    if (_supermercados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um supermercado antes de comprar.')),
      );
      return null;
    }

    Supermercado? selecionado = _supermercadoAtual ?? _supermercados.first;

    return showDialog<Supermercado>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Onde você está comprando?'),
              content: DropdownButtonFormField<Supermercado>(
                key: ValueKey(selecionado?.id),
                initialValue: selecionado,
                decoration: const InputDecoration(labelText: 'Supermercado'),
                items: _supermercados
                    .map(
                      (supermercado) => DropdownMenuItem(
                        value: supermercado,
                        child: Text(supermercado.nome),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setStateDialog(() => selecionado = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selecionado == null
                      ? null
                      : () => Navigator.pop(context, selecionado),
                  child: const Text('Começar compra'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Permite escolher o mercado antes de registrar itens.
  Future<void> _selecionarSupermercadoAtual() async {
    final supermercado = await _escolherSupermercado();
    if (supermercado != null && mounted) {
      final trocarSessao = _sessaoAtualId != null &&
          _supermercadoAtual?.id != supermercado.id;

      if (trocarSessao) {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Trocar supermercado?'),
            content: Text(
              'A compra #$_sessaoAtualId será encerrada. Os itens já salvos continuarão no histórico.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar compra'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Encerrar e trocar'),
              ),
            ],
          ),
        );
        if (confirmar != true) return;
        await widget.database.encerrarSessao(_sessaoAtualId!);
      }

      setState(() {
        if (trocarSessao) _sessaoAtualId = null;
        _supermercadoAtual = supermercado;
      });
    }
  }

  // Encerra a visita atual e deixa o histórico preservado.
  Future<void> _encerrarCompra() async {
    final sessaoId = _sessaoAtualId;
    if (sessaoId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Encerrar compra #$sessaoId?'),
        content: const Text(
          'Os itens salvos ficarão no histórico. Para continuar comprando, será iniciada uma nova compra numerada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Encerrar compra'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    await widget.database.encerrarSessao(sessaoId);
    if (!mounted) return;

    setState(() {
      _sessaoAtualId = null;
      _supermercadoAtual = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compra #$sessaoId encerrada.')),
    );
  }

  // Monta a lista de atalhos combinando o histórico do usuário com o catálogo rápido.
  List<ProdutoAtalho> _montarAtalhosProdutos() {
    final mapaAtalhos = <String, ProdutoAtalho>{};
    final contagemPorNome = <String, int>{};

    // _compras já vem ordenado da compra mais recente para a mais antiga.
    for (final compra in _compras) {
      final chave = compra.nome.trim().toUpperCase();
      contagemPorNome[chave] = (contagemPorNome[chave] ?? 0) + 1;
    }

    for (final compra in _compras) {
      final chave = compra.nome.trim().toUpperCase();
      mapaAtalhos.putIfAbsent(
        chave,
        () => ProdutoAtalho(
          nome: chave,
          categoriaNome: compra.categoriaNome,
          unidade: compra.unidade,
          ultimoPrecoUnitario: compra.precoUnitario,
          ultimoSupermercado: compra.supermercadoNome,
          vezesComprado: contagemPorNome[chave] ?? 1,
        ),
      );
    }

    // Completa com os itens do catálogo padrão que o usuário ainda não comprou.
    for (final itemPadrao in kCatalogoRapidoPadrao) {
      final chave = itemPadrao.nome.trim().toUpperCase();
      mapaAtalhos.putIfAbsent(chave, () => itemPadrao);
    }

    final lista = mapaAtalhos.values.toList();
    lista.sort((a, b) {
      final compFreq = b.vezesComprado.compareTo(a.vezesComprado);
      if (compFreq != 0) return compFreq;
      return a.nome.compareTo(b.nome);
    });
    return lista;
  }

  // Abre um popup de digitação mínima para cadastrar uma ou mais compras.
  Future<void> _adicionarCompra() async {
    // Na primeira compra, pede o supermercado e mantém a escolha para os próximos itens.
    if (_supermercadoAtual == null) {
      final supermercado = await _escolherSupermercado();
      if (supermercado == null || !mounted) return;
      setState(() => _supermercadoAtual = supermercado);
    }

    // Controladores dos campos do formulário.
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController(text: '1');
    final precoUnitarioController = TextEditingController();
    final quantidadeFocusNode = FocusNode();
    final precoFocusNode = FocusNode();
    String unidadeSelecionada = 'un';
    const unidades = ['un', 'kg', 'g', 'L', 'ml', 'pacote'];
    String filtroCategoriaRapida = 'Frequentes';
    ProdutoAtalho? atalhoSelecionado;
    bool salvouAlgumItem = false;

    List<ProdutoAtalho> todosAtalhos = _montarAtalhosProdutos();

    // Categoria padrão para um produto novo.
    Categoria? categoriaSelecionada = _categorias.isNotEmpty ? _categorias.first : null;

    Categoria? encontrarCategoriaPorNome(String nomeCat) {
      for (final categoria in _categorias) {
        if (categoria.nome.toLowerCase() == nomeCat.toLowerCase()) {
          return categoria;
        }
      }
      return _categorias.isNotEmpty ? _categorias.first : null;
    }

    // Aplica o produto tocado com 1 clique e já foca direto no preço.
    void selecionarAtalho(
      ProdutoAtalho atalho,
      void Function(void Function()) setStateDialog,
    ) {
      atalhoSelecionado = atalho;
      nomeController.text = atalho.nome;
      if (unidades.contains(atalho.unidade)) {
        unidadeSelecionada = atalho.unidade;
      }
      categoriaSelecionada =
          encontrarCategoriaPorNome(atalho.categoriaNome) ?? categoriaSelecionada;
      if (quantidadeController.text.trim().isEmpty) {
        quantidadeController.text = '1';
      }
      setStateDialog(() {});
      // Pula direto para o preço para o usuário só digitar os números.
      precoFocusNode.requestFocus();
    }

    void alterarQuantidade(
      double delta,
      void Function(void Function()) setStateDialog,
    ) {
      final atual = double.tryParse(
            quantidadeController.text.replaceAll(',', '.'),
          ) ??
          1.0;
      final passo = (unidadeSelecionada == 'kg') ? (delta * 0.5) : delta;
      final novoValor = (atual + passo).clamp(0.1, 999.0);
      final texto = (novoValor % 1 == 0)
          ? novoValor.toInt().toString()
          : novoValor.toStringAsFixed(1).replaceAll('.', ',');
      quantidadeController.text = texto;
      setStateDialog(() {});
    }

    // Valida os campos e salva a compra; pode fechar o popup ou limpar para o próximo item.
    Future<void> salvarCompra(
      BuildContext dialogContext,
      void Function(void Function()) setStateDialog, {
      required bool continuarAdicionando,
    }) async {
      final quantidade = double.tryParse(
        quantidadeController.text.replaceAll(',', '.'),
      );
      final precoUnitario = double.tryParse(
        precoUnitarioController.text.replaceAll(',', '.'),
      );

      if (nomeController.text.trim().isEmpty ||
          categoriaSelecionada == null ||
          quantidade == null ||
          quantidade <= 0 ||
          precoUnitario == null ||
          precoUnitario <= 0) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('Toque em um produto e digite o preço.'),
          ),
        );
        return;
      }

      final sessaoId = _sessaoAtualId ??
          await widget.database.iniciarSessao(_supermercadoAtual!.id!);
      _sessaoAtualId = sessaoId;

      final novaCompra = Compra(
        nome: nomeController.text.trim().toUpperCase(),
        categoriaId: categoriaSelecionada!.id!,
        categoriaNome: categoriaSelecionada!.nome,
        unidade: unidadeSelecionada,
        quantidade: quantidade,
        precoUnitario: precoUnitario,
        supermercadoId: _supermercadoAtual!.id!,
        sessaoId: sessaoId,
        supermercadoNome: _supermercadoAtual!.nome,
        dataCompra: DateTime.now(),
      );

      await widget.database.insertCompra(novaCompra);
      salvouAlgumItem = true;

      if (!dialogContext.mounted) return;

      if (continuarAdicionando) {
        await _carregarDados();
        todosAtalhos = _montarAtalhosProdutos();
        nomeController.clear();
        quantidadeController.text = '1';
        precoUnitarioController.clear();
        atalhoSelecionado = null;
        setStateDialog(() {});
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text('${novaCompra.nome} adicionado! Escolha o próximo.'),
          ),
        );
      } else {
        Navigator.pop(dialogContext, true);
      }
    }

    // showDialog cria uma janela modal estilo popup.
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final quantidadeAtual = double.tryParse(
                  quantidadeController.text.replaceAll(',', '.'),
                ) ??
                0;
            final precoUnitarioAtual = double.tryParse(
                  precoUnitarioController.text.replaceAll(',', '.'),
                ) ??
                0;
            final totalCalculado = quantidadeAtual * precoUnitarioAtual;

            final abasCategorias = [
              'Frequentes',
              ..._categorias.map((c) => c.nome),
            ];

            final atalhosVisiveis = filtroCategoriaRapida == 'Frequentes'
                ? todosAtalhos.take(14).toList()
                : todosAtalhos
                    .where(
                      (a) =>
                          a.categoriaNome.toLowerCase() ==
                          filtroCategoriaRapida.toLowerCase(),
                    )
                    .toList();

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              title: Text(
                _sessaoAtualId == null
                    ? 'Novo item • ${_supermercadoAtual!.nome}'
                    : 'Compra #$_sessaoAtualId • ${_supermercadoAtual!.nome}',
                style: const TextStyle(fontSize: 18),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Toque no produto (ou digite abaixo):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Abas horizontais de categoria para filtrar os botões rápidos.
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final aba in abasCategorias)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(
                                    aba == 'Frequentes' ? '⭐ Rápidos' : aba,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  selected: filtroCategoriaRapida == aba,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (_) {
                                    setStateDialog(() {
                                      filtroCategoriaRapida = aba;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Grade de botões de 1 toque para escolher o produto sem digitar.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 135),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final atalho in atalhosVisiveis)
                                ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: nomeController.text
                                              .trim()
                                              .toUpperCase() ==
                                          atalho.nome
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : null,
                                  label: Text(
                                    atalho.ultimoPrecoUnitario != null
                                        ? '${atalho.nome} (R\$ ${atalho.ultimoPrecoUnitario!.toStringAsFixed(2).replaceAll('.', ',')})'
                                        : atalho.nome,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => selecionarAtalho(
                                    atalho,
                                    setStateDialog,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20),

                      // Campo de busca/digitação caso o produto não esteja nos botões.
                      Autocomplete<ProdutoAtalho>(
                        textEditingController: nomeController,
                        displayStringForOption: (item) => item.nome,
                        optionsBuilder: (textEditingValue) {
                          final busca =
                              textEditingValue.text.trim().toLowerCase();
                          if (busca.isEmpty) {
                            return const Iterable<ProdutoAtalho>.empty();
                          }

                          return todosAtalhos
                              .where(
                                (item) =>
                                    item.nome.toLowerCase().contains(busca),
                              )
                              .take(6);
                        },
                        onSelected: (item) =>
                            selecionarAtalho(item, setStateDialog),
                        fieldViewBuilder: (
                          context,
                          controller,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            inputFormatters: const [UpperCaseTextFormatter()],
                            decoration: InputDecoration(
                              labelText: 'Produto selecionado',
                              hintText: 'Toque acima ou digite um novo',
                              isDense: true,
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        atalhoSelecionado = null;
                                        setStateDialog(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setStateDialog(() {}),
                            onSubmitted: (_) {
                              onFieldSubmitted();
                              precoFocusNode.requestFocus();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Preço estilo maquininha (digita 599 -> vira 5,99).
                      TextField(
                        controller: precoUnitarioController,
                        focusNode: precoFocusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: const [CentavosInputFormatter()],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              '2. Preço por $unidadeSelecionada (R\$)',
                          hintText: 'Ex: digite 599 para 5,99',
                          prefixText: 'R\$ ',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setStateDialog(() {}),
                        onSubmitted: (_) => salvarCompra(
                          context,
                          setStateDialog,
                          continuarAdicionando: false,
                        ),
                      ),

                      // Se já comprou esse produto antes, permite repetir o último preço com 1 toque.
                      if (atalhoSelecionado?.ultimoPrecoUnitario != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Último: R\$ ${atalhoSelecionado!.ultimoPrecoUnitario!.toStringAsFixed(2).replaceAll('.', ',')} (${atalhoSelecionado!.ultimoSupermercado ?? ''})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () {
                                precoUnitarioController.text =
                                    atalhoSelecionado!.ultimoPrecoUnitario!
                                        .toStringAsFixed(2)
                                        .replaceAll('.', ',');
                                setStateDialog(() {});
                              },
                              icon: const Icon(Icons.replay, size: 15),
                              label: const Text(
                                'Usar último preço',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Linha com quantidade (com botões - e +) e unidade.
                      Row(
                        children: [
                          IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                alterarQuantidade(-1, setStateDialog),
                            icon: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: quantidadeController,
                              focusNode: quantidadeFocusNode,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Qtd',
                                isDense: true,
                              ),
                              onChanged: (_) => setStateDialog(() {}),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                alterarQuantidade(1, setStateDialog),
                            icon: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(unidadeSelecionada),
                              initialValue: unidadeSelecionada,
                              decoration: const InputDecoration(
                                labelText: 'Unidade',
                                isDense: true,
                              ),
                              items: unidades
                                  .map(
                                    (unidade) => DropdownMenuItem(
                                      value: unidade,
                                      child: Text(unidade),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setStateDialog(
                                    () => unidadeSelecionada = value,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Categoria já preenchida automaticamente, mas editável se quiser.
                      DropdownButtonFormField<Categoria>(
                        key: ValueKey(categoriaSelecionada?.id),
                        initialValue: categoriaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoria (automática)',
                          isDense: true,
                        ),
                        items: _categorias
                            .map(
                              (categoria) => DropdownMenuItem(
                                value: categoria,
                                child: Text(categoria.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() => categoriaSelecionada = value);
                        },
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Subtotal do item: R\$ ${totalCalculado.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, salvouAlgumItem),
                  child: const Text('Fechar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => salvarCompra(
                    context,
                    setStateDialog,
                    continuarAdicionando: true,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Salvar +1'),
                ),
                FilledButton(
                  onPressed: () => salvarCompra(
                    context,
                    setStateDialog,
                    continuarAdicionando: false,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    // Libera os recursos de entrada associados ao formulário.
    nomeController.dispose();
    quantidadeController.dispose();
    precoUnitarioController.dispose();
    quantidadeFocusNode.dispose();
    precoFocusNode.dispose();

    // Se o popup voltou com sucesso, recarrega a tela para mostrar a nova compra.
    if (result == true || salvouAlgumItem) {
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
    final comprasPorCategoria = <String, List<Compra>>{};
    for (final compra in _compras) {
      comprasPorCategoria.putIfAbsent(compra.categoriaNome, () => []).add(compra);
    }
    final categoriasOrdenadas = comprasPorCategoria.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Compras'),
        actions: [
          IconButton(
            tooltip: 'Relatórios',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RelatoriosPage(
                    compras: _compras,
                    supermercados: _supermercados,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
          ),
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

                  // O mercado selecionado fica ativo até o usuário trocá-lo.
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Supermercado da compra'),
                    subtitle: Text(
                      _sessaoAtualId == null
                          ? (_supermercadoAtual?.nome ?? 'Selecione antes de registrar itens')
                          : 'Compra #$_sessaoAtualId • ${_supermercadoAtual!.nome}',
                    ),
                    trailing: TextButton(
                      onPressed: _selecionarSupermercadoAtual,
                      child: Text(_supermercadoAtual == null ? 'Selecionar' : 'Trocar'),
                    ),
                  ),
                  if (_sessaoAtualId != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _encerrarCompra,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text('Encerrar compra #$_sessaoAtualId'),
                      ),
                    ),

                  // Lista das compras registradas.
                  Expanded(
                    child: _compras.isEmpty
                        ? const Center(
                            child: Text('Nenhuma compra registrada ainda.'),
                          )
                        : ListView(
                            children: [
                              for (final categoria in categoriasOrdenadas) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                                  child: Text(
                                    categoria,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                for (final compra in comprasPorCategoria[categoria]!)
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(compra.nome),
                                      subtitle: Text(
                                        'Compra #${compra.sessaoId} • '
                                        '${compra.quantidade} ${compra.unidade} • ${compra.supermercadoNome}',
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
                                          Text(DateFormat('dd/MM/yyyy').format(compra.dataCompra)),
                                        ],
                                      ),
                                      onLongPress: () async {
                                        await widget.database.deleteCompra(compra.id!);
                                        _carregarDados();
                                      },
                                    ),
                                  ),
                              ],
                            ],
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

class RelatoriosPage extends StatefulWidget {
  final List<Compra> compras;
  final List<Supermercado> supermercados;

  const RelatoriosPage({
    super.key,
    required this.compras,
    required this.supermercados,
  });

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  int? _supermercadoSelecionado;

  @override
  Widget build(BuildContext context) {
    final comprasFiltradas = widget.compras
        .where((compra) =>
            _supermercadoSelecionado == null ||
            compra.supermercadoId == _supermercadoSelecionado)
        .toList();
    final comprasPorProduto = <String, List<Compra>>{};
    for (final compra in comprasFiltradas) {
      final chave = '${compra.nome.toLowerCase()}|${compra.unidade.toLowerCase()}';
      comprasPorProduto.putIfAbsent(chave, () => []).add(compra);
    }
    final gruposOrdenados = comprasPorProduto.values.toList()
      ..sort((a, b) => a.first.nome.compareTo(b.first.nome));
    final totalGasto = comprasFiltradas.fold<double>(
      0,
      (total, compra) => total + compra.preco,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de compras')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int?>(
              initialValue: _supermercadoSelecionado,
              decoration: const InputDecoration(labelText: 'Supermercado'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                ...widget.supermercados.map(
                  (supermercado) => DropdownMenuItem<int?>(
                    value: supermercado.id,
                    child: Text(supermercado.nome),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _supermercadoSelecionado = value),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${comprasFiltradas.length} compras'),
                Text(
                  'Total: R\$ ${totalGasto.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: gruposOrdenados.isEmpty
                  ? const Center(child: Text('Nenhuma compra para este filtro.'))
                  : ListView(
                      children: [
                        for (final grupo in gruposOrdenados)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              title: Text(grupo.first.nome),
                              subtitle: Text(
                                '${grupo.fold<double>(0, (soma, compra) => soma + compra.quantidade)} '
                                '${grupo.first.unidade} no total • '
                                'R\$ ${grupo.fold<double>(0, (soma, compra) => soma + compra.preco).toStringAsFixed(2)} gastos',
                              ),
                              children: [
                                for (final compra in grupo)
                                  ListTile(
                                    dense: true,
                                    title: Text(
                                      '${DateFormat('dd/MM/yyyy').format(compra.dataCompra)} • '
                                      '${compra.quantidade} ${compra.unidade}',
                                    ),
                                    subtitle: Text(
                                      '${compra.supermercadoNome} • '
                                      'R\$ ${compra.precoUnitario.toStringAsFixed(2)}/${compra.unidade}',
                                    ),
                                    trailing: Text('R\$ ${compra.preco.toStringAsFixed(2)}'),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
