/// Fallo al comunicarse con el proveedor de IA o al interpretar su respuesta.
class AiProviderException implements Exception {
  const AiProviderException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (statusCode: $statusCode)';
    return 'AiProviderException$status: $message';
  }
}
