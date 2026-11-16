// Este arquivo gerencia todo o acesso ao banco de dados local do app.
// Neste projeto usamos SQLite, que é muito bom para apps simples que precisam
// salvar registros offline no celular.

import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';
import '../models/compra.dart';
import '../models/supermercado.dart';

// Classe responsável por abrir o banco e por executar todas as operações.
class AppDatabase {
  // Padrão Singleton: garante que exista apenas uma instância do banco.
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  AppDatabase._internal();

  // A variável _database guarda a conexão ativa do SQLite.
  static Database? _database;

  // Getter que cria o banco se ainda não existir.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Cria o arquivo do banco em um diretório do dispositivo.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_compras.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Atualiza bancos existentes sem apagar as compras já registradas.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE compras ADD COLUMN preco_unitario REAL NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE compras
        SET preco_unitario = CASE
          WHEN quantidade > 0 THEN preco / quantidade
          ELSE preco
        END
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE sessoes_compra (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supermercado_id INTEGER NOT NULL,
          data_inicio TEXT NOT NULL,
          data_fim TEXT,
          FOREIGN KEY (supermercado_id) REFERENCES supermercados(id)
        )
      ''');
      await db.execute(
        'ALTER TABLE compras ADD COLUMN sessao_id INTEGER REFERENCES sessoes_compra(id)',
      );

      // Agrupa compras antigas por supermercado e dia para manter o histórico.
      final comprasAntigas = await db.query(
        'compras',
        columns: ['id', 'supermercado_id', 'data_compra'],
        orderBy: 'data_compra ASC',
      );
      final sessoesPorDia = <String, int>{};

      for (final compra in comprasAntigas) {
        final supermercadoId = compra['supermercado_id'] as int;
        final dataCompra = compra['data_compra'] as String;
        final chaveSessao = '$supermercadoId|${dataCompra.substring(0, 10)}';
        var sessaoId = sessoesPorDia[chaveSessao];

        if (sessaoId == null) {
          sessaoId = await db.insert('sessoes_compra', {
            'supermercado_id': supermercadoId,
            'data_inicio': dataCompra,
            'data_fim': dataCompra,
          });
          sessoesPorDia[chaveSessao] = sessaoId;
        } else {
          await db.update(
            'sessoes_compra',
            {'data_fim': dataCompra},
            where: 'id = ?',
            whereArgs: [sessaoId],
          );
        }

        await db.update(
          'compras',
          {'sessao_id': sessaoId},
          where: 'id = ?',
          whereArgs: [compra['id']],
        );
      }
    }
  }

  // Método chamado somente na primeira vez que o banco é criado.
  // Aqui definimos as tabelas do app: categorias, supermercados e compras.
  Future<void> _onCreate(Database db, int version) async {
    // Tabela de categorias, por exemplo: frutas, limpeza, higiene.
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL
      )
    ''');

    // Tabela de supermercados, por exemplo: mercado central, atacado, etc.
    await db.execute('''
      CREATE TABLE supermercados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL
      )
    ''' );

    // Tabela principal: todas as compras do usuário.
    await db.execute('''
      CREATE TABLE sessoes_compra (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supermercado_id INTEGER NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        FOREIGN KEY (supermercado_id) REFERENCES supermercados(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        unidade TEXT NOT NULL,
        quantidade REAL NOT NULL,
        preco REAL NOT NULL,
        preco_unitario REAL NOT NULL,
        supermercado_id INTEGER NOT NULL,
        sessao_id INTEGER NOT NULL,
        data_compra TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id),
        FOREIGN KEY (supermercado_id) REFERENCES supermercados(id),
        FOREIGN KEY (sessao_id) REFERENCES sessoes_compra(id)
      )
    ''');

    // Dados iniciais para a tela já começar funcionando.
    await db.insert('categorias', {'nome': 'Alimentos'});
    await db.insert('categorias', {'nome': 'Hortifruti'});
    await db.insert('categorias', {'nome': 'Carnes e Frios'});
    await db.insert('categorias', {'nome': 'Laticínios e Padaria'});
    await db.insert('categorias', {'nome': 'Bebidas'});
    await db.insert('categorias', {'nome': 'Higiene'});
    await db.insert('categorias', {'nome': 'Limpeza'});

    await db.insert('supermercados', {'nome': 'Mercado Família'});
    await db.insert('supermercados', {'nome': 'Supermercado do Bairro'});
  }

  // Insere uma nova categoria no banco.
  Future<int> insertCategoria(String nome) async {
    final db = await database;
    return db.insert('categorias', {'nome': nome});
  }

  // Busca todas as categorias ordenadas por nome.
  Future<List<Categoria>> getCategorias() async {
    final db = await database;
    const categoriasPadrao = [
      'Alimentos',
      'Hortifruti',
      'Carnes e Frios',
      'Laticínios e Padaria',
      'Bebidas',
      'Higiene',
      'Limpeza',
    ];
    final existentes = await db.query('categorias');
    final nomesExistentes = existentes
        .map((row) => (row['nome'] as String).trim().toLowerCase())
        .toSet();

    for (final padrao in categoriasPadrao) {
      if (!nomesExistentes.contains(padrao.toLowerCase())) {
        await db.insert('categorias', {'nome': padrao});
      }
    }

    final maps = await db.query('categorias', orderBy: 'nome ASC');
    return maps.map((map) => Categoria.fromMap(map)).toList();
  }

  // Insere um novo supermercado.
  Future<int> insertSupermercado(String nome) async {
    final db = await database;
    return db.insert('supermercados', {'nome': nome});
  }

  // Busca todos os supermercados.
  Future<List<Supermercado>> getSupermercados() async {
    final db = await database;
    final maps = await db.query('supermercados', orderBy: 'nome ASC');
    return maps.map((map) => Supermercado.fromMap(map)).toList();
  }

  // Salva uma compra no banco.
  Future<int> insertCompra(Compra compra) async {
    final db = await database;
    return db.insert('compras', compra.toMap());
  }

  // Cria uma visita numerada ao supermercado e devolve seu número automático.
  Future<int> iniciarSessao(int supermercadoId) async {
    final db = await database;
    return db.insert('sessoes_compra', {
      'supermercado_id': supermercadoId,
      'data_inicio': DateTime.now().toIso8601String(),
    });
  }

  // Retorna a sessão que ainda está aberta, caso o app tenha sido reaberto.
  Future<Map<String, dynamic>?> getSessaoAberta() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.id, s.supermercado_id
      FROM sessoes_compra s
      WHERE s.data_fim IS NULL
      ORDER BY s.id DESC
      LIMIT 1
    ''');
    return maps.isEmpty ? null : maps.first;
  }

  // Marca a sessão como encerrada sem remover seus itens do histórico.
  Future<void> encerrarSessao(int sessaoId) async {
    final db = await database;
    await db.update(
      'sessoes_compra',
      {'data_fim': DateTime.now().toIso8601String()},
      where: 'id = ? AND data_fim IS NULL',
      whereArgs: [sessaoId],
    );
  }

  // Busca todas as compras com o nome da categoria e do supermercado.
  // Isso facilita a exibição na tela principal e em relatórios.
  Future<List<Compra>> getCompras() async {
    final db = await database;

    final maps = await db.rawQuery('''
      SELECT
        c.id,
        c.nome,
        c.categoria_id,
        cat.nome AS categoria_nome,
        c.unidade,
        c.quantidade,
        c.preco,
        c.preco_unitario,
        c.supermercado_id,
        c.sessao_id,
        sup.nome AS supermercado_nome,
        c.data_compra
      FROM compras c
      INNER JOIN categorias cat ON cat.id = c.categoria_id
      INNER JOIN supermercados sup ON sup.id = c.supermercado_id
      ORDER BY c.data_compra DESC
    ''');

    return maps.map((map) => Compra.fromMap(map)).toList();
  }

  // Remove uma compra do banco.
  Future<void> deleteCompra(int id) async {
    final db = await database;
    await db.delete('compras', where: 'id = ?', whereArgs: [id]);
  }
}
