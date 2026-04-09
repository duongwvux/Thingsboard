class AuthResponse {
  final String token;
  final String refreshToken;
  final String userId;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token:        json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      // ThingsBoard trả userId trong JWT claim 'sub'
      userId:       json['sub'] as String? ?? '',
    );
  }
}
