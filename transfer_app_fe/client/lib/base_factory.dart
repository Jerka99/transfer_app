import 'package:async_redux/async_redux.dart';
import 'package:business/store/app_state.dart';
import 'package:flutter/cupertino.dart';

abstract class BaseFactory<T extends Widget?, Model extends Vm>
    extends VmFactory<AppState, T, Model> {
  BaseFactory([super.connector]);
}