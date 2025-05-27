import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../data/db.dart';
import '../generated/l10n.dart';
import '../main.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

class CacheRemoveDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CacheRemoveDialog();
  }

  static Future<void> show(BuildContext context) async {
    return await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (_context) {
        return CacheRemoveDialog();
      },
    );
  }
}

class _CacheRemoveDialog extends State<CacheRemoveDialog> {
  bool removeMediaCache = false;
  bool removeMetaCache = false;
  bool removeRelayCache = false;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var s = S.of(context);
    var cardColor = themeData.cardColor;

    List<Widget> list = [];
    list.add(Text(
      s.Remove_Cache,
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        setState(() {
          removeMediaCache = !removeMediaCache;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Expanded(
            child: Text(s.Remove_media_cache),
          ),
          Checkbox(
            value: removeMediaCache,
            onChanged: (value) {
              setState(() {
                removeMediaCache = value ?? false;
              });
            },
          ),
        ],
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        setState(() {
          removeMetaCache = !removeMetaCache;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Expanded(
            child: Text(s.Remove_meta_cache),
          ),
          Checkbox(
            value: removeMetaCache,
            onChanged: (value) {
              setState(() {
                removeMetaCache = value ?? false;
              });
            },
          ),
        ],
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        setState(() {
          removeRelayCache = !removeRelayCache;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          Expanded(
            child: Text(s.Remove_relay_cache),
          ),
          Checkbox(
            value: removeRelayCache,
            onChanged: (value) {
              setState(() {
                removeRelayCache = value ?? false;
              });
            },
          ),
        ],
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: _onConfirm,
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Confirm,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    Widget main = Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(maxHeight: mediaDataCache.size.height * 0.85),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    var cancelFunc = BotToast.showLoading();
    try {
      if (removeMediaCache) {
        imageLocalCacheManager.emptyCache();
      }
      if (removeMetaCache) {
        await DB.removeCache();
      }
      if (removeRelayCache && localRelayDB != null) {
        await localRelayDB!.deleteData();
      }
    } finally {
      cancelFunc();
    }
    RouterUtil.back(context);
  }
}
