import 'package:async_redux/async_redux.dart';
import '../../store/app_state.dart';

class LoginAction extends ReduxAction<AppState> {
  final String username;

  LoginAction(this.username);

  @override
  AppState reduce() {
    return state.copyWith(
      loginState: state.loginState.copyWith(username: username, loggedIn: true),
    );
  }
}
