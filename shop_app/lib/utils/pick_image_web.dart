// Web: výber obrázka cez html file input.
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Výsledok výberu obrázka.
class PickImageResult {
  const PickImageResult({required this.bytes, required this.mimeType});
  final Uint8List bytes;
  final String mimeType;
}

/// Otvorí dialóg na výber obrázka (web implementácia).
Future<PickImageResult?> pickImage() async {
  final input = html.InputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..style.display = 'none';
  html.document.body?.append(input);

  final completer = Completer<PickImageResult?>();
  void cleanup() {
    input.remove();
  }

  input.onChange.listen((_) {
    if (completer.isCompleted) return;
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete(null);
      cleanup();
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      if (completer.isCompleted) return;
      try {
        final result = reader.result;
        if (result == null) {
          completer.complete(null);
        } else {
          final bytes = result is Uint8List ? result : Uint8List.view(result as ByteBuffer);
          final name = file.name;
          final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
          final mime = ext == 'png' ? 'image/png' : ext == 'gif' ? 'image/gif' : 'image/jpeg';
          completer.complete(PickImageResult(bytes: bytes, mimeType: mime));
        }
      } finally {
        cleanup();
      }
    });
    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
