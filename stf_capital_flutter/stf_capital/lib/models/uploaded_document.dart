// ─────────────────────────────────────────────────────────────
//  models/uploaded_document.dart
// ─────────────────────────────────────────────────────────────
class UploadedDocument {
  final String name;
  final String type;
  final String url;

  UploadedDocument({
    required this.name,
    required this.type,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'url': url,
    };
  }
}
