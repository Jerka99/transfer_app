import 'package:business/models/cloud/cloud_list_response_state.dart';

import '../models/login/login_state.dart';

class AppState {
  final LoginState loginState;
  final List<String> localFiles;
  final CloudListResponseState cloudListResponseState;

  AppState({
    required this.loginState,
    required this.localFiles,
    required this.cloudListResponseState,
  });

  AppState copyWith({
    LoginState? loginState,
    List<String>? localFiles,
    CloudListResponseState? cloudListResponseState,
  }) => AppState(
    loginState: loginState ?? this.loginState,
    localFiles: localFiles ?? this.localFiles,
    cloudListResponseState:
        cloudListResponseState ?? this.cloudListResponseState,
  );

  factory AppState.initial() => AppState(
    loginState: LoginState.initial(),
    localFiles: [],
    cloudListResponseState: CloudListResponseState.initial(),
  );
}
