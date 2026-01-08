class LoginState {
  final String username;
  final bool loggedIn;

  LoginState({required this.username, required this.loggedIn});

  LoginState copyWith({String? username, bool? loggedIn}) {
    return LoginState(
      username: username ?? this.username,
      loggedIn: loggedIn ?? this.loggedIn,
    );
  }

  factory LoginState.initial() => LoginState(username: '', loggedIn: false);
}
