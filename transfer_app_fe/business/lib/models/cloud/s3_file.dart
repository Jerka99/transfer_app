class S3File {
  final String key;
  final int? size;
  final DateTime? lastModified;
  final bool isFolder;
  final List<S3File> children;

  S3File({
    required this.key,
    this.size,
    this.lastModified,
    this.isFolder = false,
    this.children = const [],
  });

  factory S3File.fromJson(Map<String, dynamic> json) {
    return S3File(
      key: json['key'] as String,
      size: json['size'] as int?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
      isFolder: json['isFolder'] as bool? ?? false,
      children: (json['children'] as List?)
          ?.map((e) => S3File.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'size': size,
    'lastModified': lastModified?.toIso8601String(),
    'isFolder': isFolder,
    'children': children.map((c) => c.toJson()).toList(),
  };

  static List<S3File> listFromJson(dynamic jsonData) {
    if (jsonData is List) {
      return jsonData.map((e) => S3File.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ArgumentError('Expected a List of JSON objects');
  }
}
