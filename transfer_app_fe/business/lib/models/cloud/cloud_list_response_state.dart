import 'package:business/models/cloud/s3_file.dart';

class CloudListResponseState {
  final int maxBytes;
  final int usedBytes;
  final List<S3File> items;

  CloudListResponseState({
    required this.maxBytes,
    required this.usedBytes,
    required this.items,
  });

  factory CloudListResponseState.initial() =>
      CloudListResponseState(maxBytes: 0, usedBytes: 0, items: []);

  factory CloudListResponseState.fromJson(Map<String, dynamic> json) {
    return CloudListResponseState(
      maxBytes: json['maxBytes'] as int,
      usedBytes: json['usedBytes'] as int,
      items: (json['items'] as List)
          .map((e) => S3File.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'maxBytes': maxBytes,
    'usedBytes': usedBytes,
    'items': items.map((e) => e.toJson()).toList(),
  };

  double get usageRatio => maxBytes == 0 ? 0 : usedBytes / maxBytes;

  int get remainingBytes => maxBytes - usedBytes;
}
