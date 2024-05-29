class Usuario {
  final String nomecompleto;
  final String cpf;
  final String telefone;
  final int? id;
  final String token;

  Usuario({
    required this.nomecompleto,
    this.cpf='',
    this.telefone='',
    this.id,
    this.token=''
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nomecompleto: json['nomecompleto'] ?? '', // Usar valor padrão se for null
      cpf: json['cpf'] ?? '',                   // Usar valor padrão se for null
      telefone: json['telefone'] ?? '',         // Usar valor padrão se for null
      id: json['id'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeCompleto': nomecompleto,
      'cpf': cpf,
      'telefone': telefone,
    };
  }

}
