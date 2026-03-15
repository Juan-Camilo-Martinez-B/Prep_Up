import 'dart:typed_data';

abstract class VideoStorageService {
  Future<String> uploadInterviewVideo({
    required String sessionId,
    required Uint8List bytes,
    String? contentType,
  });

  Future<Uri> getDownloadUrl(String videoReference);
  Future<void> deleteVideo(String videoReference);

  // TODO: almacenar videos en base de datos no relacional / blob storage.
}

class FakeVideoStorageService implements VideoStorageService {
  final Map<String, Uint8List> _store = {};

  @override
  Future<String> uploadInterviewVideo({
    required String sessionId,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final reference = 'video://session/$sessionId/${DateTime.now().millisecondsSinceEpoch}';
    _store[reference] = bytes;
    return reference;
  }

  @override
  Future<Uri> getDownloadUrl(String videoReference) async {
    return Uri.parse('https://example.invalid/download?ref=$videoReference');
  }

  @override
  Future<void> deleteVideo(String videoReference) async {
    _store.remove(videoReference);
  }
}
