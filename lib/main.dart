import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screenLogin.dart';
import 'telainicial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seu App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Tela de carregamento
          } else {
            if (snapshot.data == true) {
              return TelaInicial();
            } else {
              return UserLoginScreen();
            }
          }
        },
      ),
    );
  }
}
