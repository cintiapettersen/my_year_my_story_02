import 'package:myyearmystory/utils/access_control.dart';
import 'session_service.dart';

class AccessPolicy {
  static Future<bool> isPremium() async {
    if (SessionService.isGuest) return false;
    return AccessControl.isPremium();
  }

  static Future<bool> canCreate({
    required int currentCount,
    required int freeLimit,
  }) async {
    if (SessionService.isGuest) return true;

    final premium = await isPremium();
    if (premium) return true;

    return currentCount < freeLimit;
  }
}
