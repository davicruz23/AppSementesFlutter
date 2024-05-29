// lib/produto.dart
class Produto {
  final String nome;
  final String tipo;
  final int quantidade;

  Produto({
    required this.nome,
    required this.tipo,
    required this.quantidade,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      nome: json['nome'],
      tipo: json['tipo'],
      quantidade: json['quantidade'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'quantidade': quantidade,
    };
  }
}
