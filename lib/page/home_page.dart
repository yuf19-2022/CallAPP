import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:call/data/phone_info.dart';
import 'package:call/utls/db_util.dart';
import 'package:call/utls/flavor_util.dart';
import 'package:call/utls/style_util.dart';
import 'package:call/utls/system_call_util.dart';
import 'package:call/utls/voice_vibration_util.dart';
import 'package:call/utls/widget_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Theme.of(context).brightness,
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return ValueListenableBuilder(
              valueListenable: PhoneInfo.globalInfoList,
              builder:
                  (BuildContext context, List<PhoneInfo> value, Widget? child) {
                    return value.isNotEmpty
                        ? GridView.count(
                            crossAxisCount: orientation == Orientation.portrait
                                ? 2
                                : 4,
                            padding: const EdgeInsets.all(5),
                            childAspectRatio: 1.2,
                            children: List.generate(value.length, (i) {
                              return _infoCard(context, value[i]);
                            }),
                          )
                        : _noContact(context, orientation);
                  },
            );
          },
        ),
      ),
    );
  }

  Widget _noContact(BuildContext context, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 20,
            children: [
              Icon(
                CupertinoIcons.person_2,
                size: 200,
                color: Theme.of(context).colorScheme.primary,
              ),
              Text(
                '没有联系人',
                style: StyleUtil.buttonTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              ListTile(
                subtitle: Text(
                  '注意：当有联系人之后，想要进入菜单的话，需要长按任意一个联系人不松手，1秒后手指拖动至屏幕最左上角后再松开！切记切记！！！',
                  style: StyleUtil.trailingTextStyle,
                ),
              ),
              SizedBox(height: 60),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPage()),
                  );
                },
                child: SizedBox(
                  width: 160,
                  height: 60,
                  child: Center(
                    child: Text('进入菜单', style: StyleUtil.textStyle),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    size: 180,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    '没有联系人',
                    style: StyleUtil.buttonTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 60,
                children: [
                  SizedBox(
                    width: 300,
                    child: Text(
                      '注意：当有联系人之后，想要进入菜单的话，需要长按任意一个联系人不松手，1秒后手指拖动至屏幕最左上角后再松开！切记切记！！！',
                      style: StyleUtil.trailingTextStyle,
                      maxLines: 10,
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MenuPage()),
                      );
                    },
                    child: SizedBox(
                      width: 160,
                      height: 60,
                      child: Center(
                        child: Text('进入菜单', style: StyleUtil.textStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _infoCard(BuildContext context, PhoneInfo info) {
    Offset startOffset = Offset.infinite;
    return GestureDetector(
      onTap: () => _onTap(info),
      onLongPressStart: (LongPressStartDetails details) {
        startOffset = details.globalPosition;
      },
      onLongPressEnd: (LongPressEndDetails details) {
        Offset endOffset = details.globalPosition;
        bool distance = (endOffset - startOffset).distance > 100;
        bool leftTop = (endOffset.dx < 100 && endOffset.dy < 100);
        if (distance && leftTop) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MenuPage()),
          );
        }
      },
      child: Card(color: info.color(), child: _picture(info)),
    );
  }

  Widget _picture(PhoneInfo info) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: info.photo.isNotEmpty
            ? info.photo.contains('/')
                  ? Image.file(
                      File(info.photo),
                      fit: BoxFit.cover,
                      errorBuilder: WidgetUtil.errorImage,
                    )
                  : Image.asset(
                      'assets/${FlavorUtil.flavor()}/${info.photo}',
                      fit: BoxFit.cover,
                      errorBuilder: WidgetUtil.errorImage,
                    )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: AutoSizeText(
                    info.name,
                    style: StyleUtil.textLargeBlack,
                    maxLines: 1,
                  ),
                ),
              ),
      ),
    );
  }

  /// 点击联系人：播报 + 震动后直接拨打系统视频电话。
  void _onTap(PhoneInfo info) {
    TtsVibrationUtil().speak(info);
    TtsVibrationUtil().vibration();
    _systemVideo(info);
  }

  /// 拨打系统视频电话（走默认电话应用，与微信无关）。
  Future<void> _systemVideo(PhoneInfo info) async {
    final bool open = await SystemCallUtil().video(info.phone);
    if (!open) {
      WidgetUtil.showToast(
        Platform.isAndroid ? '无法发起系统视频通话，请检查电话权限' : '暂不支持系统视频通话',
      );
      return;
    }
    DbUtil().addRecord(info);
  }
}
