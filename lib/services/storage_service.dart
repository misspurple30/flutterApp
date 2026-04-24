import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref('profile_photos/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadChatImageFromFile({
    required String roomId,
    required File file,
  }) async {
    final ref = _storage.ref('chat_images/$roomId/${_uuid.v4()}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Variante web qui utilise les octets (ImagePicker renvoie des bytes sur le web).
  Future<String> uploadChatImageFromBytes({
    required String roomId,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('chat_images/$roomId/${_uuid.v4()}.jpg');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
