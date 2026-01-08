import 'package:business/models/cloud/s3_file.dart';

import '../models/login/login_state.dart';

class AppState {
  final LoginState loginState;
  final List<String> localFiles;
  final List<S3File> cloudFiles;

  AppState({
    required this.loginState,
    required this.localFiles,
    required this.cloudFiles,
  });

  AppState copyWith({
    LoginState? loginState,
    List<String>? localFiles,
    List<S3File>? cloudFiles,
  }) => AppState(
    loginState: loginState ?? this.loginState,
    localFiles: localFiles ?? this.localFiles,
    cloudFiles: cloudFiles ?? this.cloudFiles,
  );

  factory AppState.initial() => AppState(
    loginState: LoginState.initial(),
    localFiles: [],
    cloudFiles: [],
  );
}
