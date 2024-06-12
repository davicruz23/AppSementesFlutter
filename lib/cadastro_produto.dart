  // lib/cadastro_produto.dart
  import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import '../domain/produto.dart';

  class CadastroProdutoScreen extends StatefulWidget {
    @override
    _CadastroProdutoScreenState createState() => _CadastroProdutoScreenState();
  }

  class _CadastroProdutoScreenState extends State<CadastroProdutoScreen> {
    final _formKey = GlobalKey<FormState>();
    String _nome = '';
    String _tipo = '';
    int _quantidade = 0;
    bool _isLoading = false;

    Future<void> _inserirProduto(Produto produto) async {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('auth_token');
        int? userId = prefs.getInt('user_id');

        print('Token: $token, UserID: $userId');

        if (token == null || userId == null) {
          print('Token ou ID do usuário não encontrados');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Token ou ID do usuário não encontrados'),
          ));
          return;
        }

        setState(() {
          _isLoading = true;
        });

        final url = 'https://sementes-render.onrender.com/produtos/$userId';
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(produto.toJson()),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context, true); // Retorna true para indicar sucesso
        } else {
          print("Falha ao inserir produto: ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao inserir produto: ${response.statusCode}'),
          ));
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print("Erro durante a requisição: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro durante a requisição: $e'),
        ));
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cadastro de Produto'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nome'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome do produto';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _nome = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Tipo'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o tipo do produto';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _tipo = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Quantidade'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a quantidade';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _quantidade = int.parse(value!);
                  },
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            Produto produto = Produto(
                              nome: _nome,
                              tipo: _tipo,
                              quantidade: _quantidade,
                            );
                            _inserirProduto(produto);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Por favor, preencha todos os campos'),
                            ));
                          }
                        },
                        child: Text('Inserir Produto'),
                      ),
              ],
            ),
          ),
        ),
      );
    }
  }
