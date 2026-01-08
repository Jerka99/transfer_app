import 'dart:convert';

class S3File {
  final String key;
  final int size;
  final DateTime lastModified;

  S3File({required this.key, required this.size, required this.lastModified});

  factory S3File.fromJson(Map<String, dynamic> json) {
    return S3File(
      key: json['key'] as String,
      size: json['size'] as int,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'size': size,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  static List<S3File> listFromJson(dynamic jsonData) {
    if (jsonData is List) {
      return jsonData
          .map((e) => S3File.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ArgumentError('Expected a List of JSON objects');
  }
}
