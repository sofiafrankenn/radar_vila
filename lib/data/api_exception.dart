/// Erro de acesso a dados com mensagem pronta para o usuário.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
