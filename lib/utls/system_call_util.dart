import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// 系统电话（默认电话应用 / 运营商电话）拨打封装。
///
/// - [voice]：普通系统语音电话。
/// - [video]：系统视频电话（与微信无关）。
///
/// 视频通过默认电话应用的 `android.intent.action.CALL` 加上
/// `android.telecom.extra.START_CALL_WITH_VIDEO_STATE`
/// （`VideoProfile.STATE_BIDIRECTIONAL` = 3，双向视频）实现。
/// 是否真正以视频发起由机型和运营商是否支持视频通话决定。
class SystemCallUtil {
  factory SystemCallUtil() => _instance;

  SystemCallUtil._internal();

  static final SystemCallUtil _instance = SystemCallUtil._internal();

  /// `VideoProfile.STATE_BIDIRECTIONAL`，双向视频。
  static const int _videoStateBidirectional = 3;

  /// 告知电信框架以视频状态发起通话的 extra key。
  static const String _extraStartCallWithVideoState =
      'android.telecom.extra.START_CALL_WITH_VIDEO_STATE';

  /// 拨打系统语音电话，返回是否成功拉起。
  Future<bool> voice(String phone) => _dial(phone);

  /// 拨打系统视频电话，返回是否成功拉起。
  Future<bool> video(String phone) => _dial(phone, video: true);

  Future<bool> _dial(String phone, {bool video = false}) async {
    final String number = phone.trim();
    if (number.isEmpty) return false;

    if (Platform.isAndroid) {
      if (await Permission.phone.request().isGranted) {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.CALL',
          data: 'tel:$number',
          arguments: video
              ? const <String, dynamic>{
                  _extraStartCallWithVideoState: _videoStateBidirectional,
                }
              : const <String, dynamic>{},
        );
        await intent.launch();
        return true;
      }
      // 视频必须走 ACTION_CALL，无电话权限时无法直接发起。
      if (video) return false;
    } else if (video) {
      // 非 Android 平台不支持系统视频电话。
      return false;
    }

    // 非直接拨号场景（无权限 / 非 Android）：退回 tel: 协议打开拨号盘。
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return true;
    }
    return false;
  }
}
