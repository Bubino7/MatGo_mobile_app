// IO (mobile/desktop): výber obrázka cez file_picker.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Výsledok výberu obrázka.
class PickImageResult {
  const PickImageResult({required this.bytes, required this.mimeType});
  final Uint8List bytes;
  final String mimeType;
}

/// Otvorí dialóg na výber obrázka (IO implementácia).
Future<PickImageResult?> pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  final ext = file.extension?.toLowerCase() ?? 'jpg';
  final mime = ext == 'png' ? 'image/png' : ext == 'gif' ? 'image/gif' : 'image/jpeg';
  return PickImageResult(bytes: Uint8List.fromList(bytes), mimeType: mime);
}
