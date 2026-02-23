class UserModel {
  final String token;
  final String tipoToken;
  final int usuarioId;
  final String username;
  final String nombreCompleto;
  final String rol;
  final int expiresIn;

  UserModel({
    required this.token,
    required this.tipoToken,
    required this.usuarioId,
    required this.username,
    required this.nombreCompleto,
    required this.rol,
    required this.expiresIn,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      tipoToken: json['tipoToken'] ?? 'Bearer',
      usuarioId: json['usuarioId'] ?? 0,
      username: json['username'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      rol: json['rol'] ?? '',
      expiresIn: json['expiresIn'] ?? 3600,
    );
  }
}