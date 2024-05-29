import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:appsementes/domain/usuario.dart';
import 'package:appsementes/domain/produto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      onCreate: _onCreate,
      version: 1,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        nomeCompleto TEXT,
        cpf TEXT,
        telefone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY,
        usuarioId INTEGER,
        nome TEXT,
        tipo TEXT,
        quantidade INTEGER,
        FOREIGN KEY (usuarioId) REFERENCES usuarios (id)
      )
    ''');
  }

  Future<void> insertUsuario(Usuario usuario) async {
    final db = await database;
    await db.insert('usuarios', usuario.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProduto(int usuarioId, Produto produto) async {
    final db = await database;
    await db.insert('produtos', {
      'usuarioId': usuarioId,
      'nome': produto.nome,
      'tipo': produto.tipo,
      'quantidade': produto.quantidade,
    });
  }

  Future<List<Produto>> getProdutosByUsuarioId(int usuarioId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'produtos',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
    );

    return List.generate(maps.length, (i) {
      return Produto(
        nome: maps[i]['nome'],
        tipo: maps[i]['tipo'],
        quantidade: maps[i]['quantidade'],
      );
    });
  }
}
