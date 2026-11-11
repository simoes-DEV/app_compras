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
      version: 1,
      onCreate: _onCreate,
    );
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
      CREATE TABLE compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria_id INTEGER NOT NULL,
        unidade TEXT NOT NULL,
        quantidade REAL NOT NULL,
        preco REAL NOT NULL,
        supermercado_id INTEGER NOT NULL,
        data_compra TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id),
        FOREIGN KEY (supermercado_id) REFERENCES supermercados(id)
      )
    ''');

    // Dados iniciais para a tela já começar funcionando.
    await db.insert('categorias', {'nome': 'Alimentos'});
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
        c.supermercado_id,
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
