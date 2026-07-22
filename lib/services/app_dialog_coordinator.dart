import 'package:flutter/material.dart';

/// Coordinates app-owned dialogs and observes unmanaged popup routes.
class AppDialogCoordinator {
  AppDialogCoordinator._();

  static final AppDialogCoordinator instance = AppDialogCoordinator._();

  late final NavigatorObserver observer = _DialogNavigatorObserver(this);

  int _popupRouteCount = 0;
  bool _managedDialogOpen = false;

  bool get isDialogOpen => _managedDialogOpen || _popupRouteCount > 0;

  bool tryBeginDialog() {
    if (isDialogOpen) return false;
    _managedDialogOpen = true;
    return true;
  }

  void endDialog() {
    _managedDialogOpen = false;
  }

  void _popupPushed() => _popupRouteCount++;

  void _popupRemoved() {
    if (_popupRouteCount > 0) _popupRouteCount--;
  }
}

class _DialogNavigatorObserver extends NavigatorObserver {
  _DialogNavigatorObserver(this.coordinator);

  final AppDialogCoordinator coordinator;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) coordinator._popupPushed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) coordinator._popupRemoved();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute<dynamic>) coordinator._popupRemoved();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute is PopupRoute<dynamic>) coordinator._popupRemoved();
    if (newRoute is PopupRoute<dynamic>) coordinator._popupPushed();
  }
}
