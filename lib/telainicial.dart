import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'screenLogin.dart';
import 'package:appsementes/domain/usuario.dart';
import 'package:appsementes/helper/database_helper.dart';
import 'package:appsementes/cadastro_produto.dart';
import 'package:appsementes/domain/produto.dart';

class TelaInicial extends StatefulWidget {
  @override
  _TelaInicialState createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  Usuario? _usuario;
  List<Produto> _meusProdutos = [];
  List<Map<String, dynamic>> _usersWithProducts = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Produto> _produtos = [];
  late WebSocketChannel channel;
  late StreamController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StreamController.broadcast();
    _initializeWebSocket();
    _checkAuthStatus().then((token) {
      if (token != null) {
        _fetchUserData(token);
        _fetchUserProducts(token);
        _fetchUsersWithProducts(token);
        _fetchProdutos(); // Carrega a lista de produtos ao iniciar a tela
      }
    });
  }

  void _initializeWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://sementes-render.onrender.com/ws'),
    );

    channel.stream.listen((message) {
      // Se a mensagem recebida for um novo produto, atualize a lista
      if (message == 'new_product') {
        _fetchProdutos();
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserLoginScreen()),
    );
  }

  Future<void> _fetchProdutos() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      int? userId = prefs.getInt('user_id');

      print('Fetching products with Token: $token, UserID: $userId');

      if (token == null || userId == null) {
        print('Token ou ID do usuário não encontrados');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Token ou ID do usuário não encontrados'),
        ));
        return;
      }

      final url =
          'https://sementes-render.onrender.com/produtos/$userId/produtos';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> produtosJson = json.decode(response.body);
        setState(() {
          _produtos =
              produtosJson.map((json) => Produto.fromJson(json)).toList();
        });
      } else {
        print("Falha ao buscar produtos: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao buscar produtos: ${response.statusCode}'),
        ));
      }
    } catch (e) {
      print("Erro durante a requisição: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro durante a requisição: $e'),
      ));
    }
  }

  Future<String?> _checkAuthStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserLoginScreen()),
      );
      throw 'Token não encontrado';
    } else {
      return token;
    }
  }

  Future<void> _fetchUserData(String token) async {
    try {
      final url = 'https://sementes-render.onrender.com/usuario/me';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print("Response data: $responseData");

        Usuario usuario = Usuario.fromJson(responseData);
        setState(() {
          _usuario = usuario;
        });

        await _dbHelper.insertUsuario(usuario);
        print(
            "Usuário salvo na classe: ${_usuario?.nomecompleto}, ${_usuario?.cpf}, ${_usuario?.telefone}");
      } else {
        print("Falha ao buscar dados do usuário: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro durante a requisição: $e");
    }
  }

  Future<void> _fetchUserProducts(String token) async {
    if (_usuario == null) return;

    try {
      final url =
          'https://sementes-render.onrender.com/produtos/${_usuario!.id}';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body) as List;
        print("Produtos: $responseData");

        setState(() {
          _meusProdutos = responseData
              .map((produtoJson) => Produto.fromJson(produtoJson))
              .toList();
        });

        for (var produto in _meusProdutos) {
          await _dbHelper.insertProduto(_usuario!.id!, produto);
        }
      } else {
        print("Falha ao buscar produtos: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro durante a requisição: $e");
    }
  }

  Future<void> _fetchUsersWithProducts(String token) async {
    try {
      final url = 'https://sementes-render.onrender.com/usuario/lista';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print("Response data: $responseData");

        setState(() {
          _usersWithProducts = List<Map<String, dynamic>>.from(responseData);
        });
      } else {
        print("Falha ao buscar usuários e produtos: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro durante a requisição: $e");
    }
  }

  Future<void> _navigateToCadastroProduto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CadastroProdutoScreen()),
    );

    if (result == true) {
      _checkAuthStatus().then((token) {
        if (token != null) {
          _fetchUserProducts(token);
          _fetchProdutos(); // Atualiza a lista de produtos após inserir um novo
        }
      });
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Bem Vindo, ${_usuario?.nomecompleto ?? 'Usuário'}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          backgroundColor:
              Color.fromARGB(255, 146, 235, 138), // Cor de fundo da app bar
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'Início',
                icon: Icon(Icons.home),
              ),
              Tab(
                text: 'Contatos',
                icon: Icon(Icons.contacts),
              ),
              Tab(
                text: 'Meus Produtos',
                icon: Icon(Icons.shopping_bag),
              ),
            ],
            labelStyle: TextStyle(fontSize: 16),
            indicatorColor: Colors.white,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildUsersWithProducts(),
            Center(
              child: Text(
                'Contatos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            _buildProdutosTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersWithProducts() {
    return ListView.builder(
      itemCount: _usersWithProducts.length,
      itemBuilder: (context, index) {
        var user = _usersWithProducts[index];
        var userName = user['nome'] ?? 'Nome não disponível';
        var products = user['produtos'] as List<dynamic>? ?? [];

        if (_usuario != null && userName == _usuario!.nomecompleto) {
          return Container();
        }

        return Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            title: Text(
              userName,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Quantidade de Produtos: ${products.length}',
              style: TextStyle(fontSize: 16),
            ),
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            onTap: () {
              _showProductsDialog(products);
            },
          ),
        );
      },
    );
  }

  Widget _buildProdutosTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _produtos.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text(
                    _produtos[index].nome,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _produtos[index].tipo,
                    style: TextStyle(fontSize: 16),
                  ),
                  trailing: Text(
                    _produtos[index].quantidade.toString(),
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    // Add functionality here if needed
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _navigateToCadastroProduto,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Inserir Novo Produto',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProductsDialog(List<dynamic> products) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Produtos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: products.map<Widget>((product) {
              return ListTile(
                title: Text(
                  'Nome: ${product['nome'] ?? 'Nome não disponível'}',
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo: ${product['tipo'] ?? 'Tipo não disponível'}',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Quantidade: ${product['quantidade'] ?? 0}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Fechar',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }
}
