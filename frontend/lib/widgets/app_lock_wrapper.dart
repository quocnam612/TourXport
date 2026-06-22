import 'package:flutter/material.dart';
import '../utils/auth_storage.dart';
import '../screens/pin_lock_screen.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const AppLockWrapper({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isShowingPin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinAndShow();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPinAndShow();
    }
  }

  Future<void> _checkPinAndShow() async {
    if (_isShowingPin) return;
    final pin = await AuthStorage.getAppPin();
    if (pin != null && pin.isNotEmpty) {
      _isShowingPin = true;
      await widget.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const PinLockScreen(mode: PinMode.verify)),
      );
      _isShowingPin = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
