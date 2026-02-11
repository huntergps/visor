class AuthUser {
  final int id;
  final String name;
  final bool editorVisor;
  final bool vendedor;
  final bool imprimirPvpVisor;

  const AuthUser({
    required this.id,
    required this.name,
    required this.editorVisor,
    required this.vendedor,
    required this.imprimirPvpVisor,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['ID'] ?? 0,
      name: json['NAME'] ?? '',
      editorVisor: json['EDITOR_VISOR'] ?? false,
      vendedor: json['VENDEDOR'] ?? false,
      imprimirPvpVisor: json['IMPRIMIR_PVP_VISOR'] ?? false,
    );
  }
}
