class SignedUrlResponse {
  final String url;
  final int expiresIn;

  SignedUrlResponse({
    required this.url,
    required this.expiresIn,
  });

  factory SignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return SignedUrlResponse(
      url: json['url'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'expiresIn': expiresIn,
    };
  }
}
