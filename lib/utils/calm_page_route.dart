import 'package:flutter/cupertino.dart';

class CalmPageRoute<T> extends CupertinoPageRoute<T> {
  CalmPageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);
}
