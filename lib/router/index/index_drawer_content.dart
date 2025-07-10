import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/user/metadata_top_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/dm_session_info_db.dart';
import 'package:nostrmo/data/event_db.dart';
import 'package:nostrmo/data/metadata_db.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/webview_provider.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:nostrmo/router/user/user_statistics_component.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/add_btn_wrapper_component.dart';
import '../../component/user/metadata_component.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../provider/uploader.dart';
import '../../util/table_mode_util.dart';
import '../edit/editor_router.dart';
import 'account_manager_component.dart';

class IndexDrawerContentComponnent extends StatefulWidget {
  bool smallMode;

  IndexDrawerContentComponnent({
    required this.smallMode,
  });

  @override
  State<StatefulWidget> createState() {
    return _IndexDrawerContentComponnent();
  }
}

class _IndexDrawerContentComponnent
    extends State<IndexDrawerContentComponnent> {
  ScrollController userStatisticscontroller = ScrollController();

  double profileEditBtnWidth = 40;

  bool readOnly = false;

  @override
  Widget build(BuildContext context) {
    var _indexProvider = Provider.of<IndexProvider>(context);

    var s = S.of(context);
    var pubkey = nostr!.publicKey;
    var paddingTop = mediaDataCache.padding.top;
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    List<Widget> list = [];
    readOnly = nostr!.isReadOnly();

    if (widget.smallMode) {
      list.add(Container(
        margin: EdgeInsets.only(
          top: Base.BASE_PADDING + paddingTop,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.USER, pubkey);
          },
          child: UserPicComponent(pubkey: pubkey, width: 50),
        ),
      ));
    } else {
      list.add(Container(
        // margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
        child: Stack(children: [
          Selector<MetadataProvider, Metadata?>(
            builder: (context, metadata, child) {
              return MetadataTopComponent(
                pubkey: pubkey,
                metadata: metadata,
                isLocal: true,
                jumpable: true,
              );
            },
            selector: (context, _provider) {
              return _provider.getMetadata(pubkey);
            },
          ),
          Positioned(
            top: paddingTop + Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING,
            child: readOnly
                ? Container()
                : Container(
                    height: profileEditBtnWidth,
                    width: profileEditBtnWidth,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(profileEditBtnWidth / 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_square),
                      onPressed: jumpToProfileEdit,
                    ),
                  ),
          ),
        ]),
      ));

      list.add(GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (detail) {
          userStatisticscontroller
              .jumpTo(userStatisticscontroller.offset - detail.delta.dx);
        },
        child: SingleChildScrollView(
          controller: userStatisticscontroller,
          scrollDirection: Axis.horizontal,
          child: UserStatisticsComponent(pubkey: pubkey),
        ),
      ));
    }

    List<Widget> centerList = [];
    if (TableModeUtil.isTableMode()) {
      centerList.add(IndexDrawerItem(
        iconData: Icons.home_rounded,
        name: s.Home,
        color: _indexProvider.currentTap == 0 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(0);
        },
        onDoubleTap: () {
          indexProvider.followScrollToTop();
        },
        smallMode: widget.smallMode,
      ));
      centerList.add(IndexDrawerItem(
        iconData: Icons.public_rounded,
        name: s.Globals,
        color: _indexProvider.currentTap == 1 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(1);
        },
        onDoubleTap: () {
          indexProvider.globalScrollToTop();
        },
        smallMode: widget.smallMode,
      ));
      centerList.add(IndexDrawerItem(
        iconData: Icons.search_rounded,
        name: s.Search,
        color: _indexProvider.currentTap == 2 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(2);
        },
        smallMode: widget.smallMode,
      ));
      centerList.add(IndexDrawerItem(
        iconData: Icons.mail_rounded,
        name: s.Chat,
        color: _indexProvider.currentTap == 3 ? mainColor : null,
        onTap: () {
          indexProvider.setCurrentTap(3);
        },
        smallMode: widget.smallMode,
      ));
    }

    centerList.add(IndexDrawerItem(
      iconData: Icons.wallet,
      name: s.Wallet,
      onTap: () {
        RouterUtil.router(context, RouterPath.WALLET);
      },
      smallMode: widget.smallMode,
    ));

    centerList.add(IndexDrawerItem(
      iconData: Icons.block_rounded,
      name: s.Filter,
      onTap: () {
        RouterUtil.router(context, RouterPath.FILTER);
      },
      smallMode: widget.smallMode,
    ));

    if (!TableModeUtil.isTableMode()) {
      centerList.add(IndexDrawerItem(
        iconData: Icons.cloud_rounded,
        name: s.Relays,
        onTap: () {
          RouterUtil.router(context, RouterPath.RELAYS);
        },
        smallMode: widget.smallMode,
      ));
    }

    if (!readOnly) {
      centerList.add(IndexDrawerItem(
        iconData: Icons.key_rounded,
        name: s.Key_Backup,
        onTap: () {
          RouterUtil.router(context, RouterPath.KEY_BACKUP);
        },
        smallMode: widget.smallMode,
      ));
    }

    centerList.add(IndexDrawerItem(
      iconData: Icons.bookmarks_rounded,
      name: s.Bookmark,
      onTap: () {
        RouterUtil.router(context, RouterPath.BOOKMARK);
      },
      smallMode: widget.smallMode,
    ));

    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      centerList.add(IndexDrawerItem(
        iconData: Icons.coffee_outlined,
        name: s.Donate,
        onTap: () {
          RouterUtil.router(context, RouterPath.DONATE);
        },
        smallMode: widget.smallMode,
      ));
    }

    centerList.add(IndexDrawerItem(
      iconData: Icons.settings_rounded,
      name: s.Setting,
      onTap: () {
        RouterUtil.router(context, RouterPath.SETTING);
      },
      smallMode: widget.smallMode,
    ));

    if (!PlatformUtil.isPC()) {
      centerList.add(
          Selector<WebViewProvider, String?>(builder: (context, url, child) {
        if (StringUtil.isBlank(url)) {
          return IndexDrawerItem(
            iconData: Icons.view_list_rounded,
            name: s.Web_Utils,
            onTap: () {
              RouterUtil.router(context, RouterPath.WEBUTILS);
            },
            smallMode: widget.smallMode,
          );
        }

        return IndexDrawerItem(
          iconData: Icons.public_rounded,
          name: s.Show_web,
          onTap: () {
            webViewProvider.show();
          },
          smallMode: widget.smallMode,
        );
      }, selector: (context, _provider) {
        return _provider.url;
      }));
    }

    list.add(Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: centerList,
        ),
      ),
    ));

    if (TableModeUtil.isTableMode() && !readOnly) {
      list.add(AddBtnWrapperComponent(
        child: IndexDrawerItem(
          iconData: Icons.add_rounded,
          name: s.Add,
          onTap: () {
            // EditorRouter.open(context);
          },
          onLongPress: () {
            Uploader.pickAndUpload2NIP95(context);
          },
          smallMode: widget.smallMode,
        ),
      ));
    }

    list.add(IndexDrawerItem(
      iconData: Icons.account_box_rounded,
      name: s.Account_Manager,
      onTap: () {
        _showBasicModalBottomSheet(context);
      },
      smallMode: widget.smallMode,
    ));

    if (widget.smallMode) {
      list.add(Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: IndexDrawerItem(
          iconData: Icons.last_page_rounded,
          name: "",
          onTap: toggleSmallMode,
          smallMode: widget.smallMode,
        ),
      ));
    } else {
      Widget versionWidget = Text("V " + Base.VERSION_NAME);

      if (TableModeUtil.isTableMode()) {
        List<Widget> subList = [];
        subList.add(GestureDetector(
          onTap: toggleSmallMode,
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING),
            child: Icon(Icons.first_page_rounded),
          ),
        ));
        subList.add(versionWidget);

        versionWidget = Row(
          children: subList,
          crossAxisAlignment: CrossAxisAlignment.start,
        );
      }

      list.add(Container(
        margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING * 2,
          bottom: Base.BASE_PADDING,
          top: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
          width: 1,
          color: hintColor,
        ))),
        alignment: Alignment.centerLeft,
        child: versionWidget,
      ));
    }

    return Container(
      color: themeData.cardColor,
      margin:
          TableModeUtil.isTableMode() ? const EdgeInsets.only(right: 1) : null,
      child: Column(
        children: list,
      ),
    );
  }

  void jumpToProfileEdit() {
    var metadata = metadataProvider.getMetadata(nostr!.publicKey);
    RouterUtil.router(context, RouterPath.PROFILE_EDITOR, metadata);
  }

  void _showBasicModalBottomSheet(context) async {
    showModalBottomSheet(
      isScrollControlled: false, // true 为 全屏
      context: context,
      builder: (BuildContext context) {
        return AccountManagerComponent();
      },
    );
  }

  toggleSmallMode() {
    var callback = IndexPcDrawerWrapperCallback.of(context);
    if (callback != null) {
      callback.toggle();
    }
  }
}

class IndexDrawerItem extends StatelessWidget {
  IconData iconData;

  String name;

  Function onTap;

  Function? onDoubleTap;

  Function? onLongPress;

  Color? color;

  // bool borderTop;

  bool smallMode;

  IndexDrawerItem({
    required this.iconData,
    required this.name,
    required this.onTap,
    this.color,
    this.onDoubleTap,
    this.onLongPress,
    this.smallMode = false,
    // this.borderTop = true,
    // this.borderBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;

    Widget iconWidget = Icon(
      iconData,
      color: color,
    );

    Widget mainWidget;
    if (smallMode) {
      mainWidget = Container(
        decoration: BoxDecoration(
          color: color != null ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: EdgeInsets.all(8),
        margin: EdgeInsets.only(bottom: 2),
        child: iconWidget,
      );
    } else {
      List<Widget> list = [];
      list.add(Container(
        margin: const EdgeInsets.only(
          left: Base.BASE_PADDING * 2,
          right: Base.BASE_PADDING,
        ),
        child: iconWidget,
      ));
      list.add(Text(name, style: TextStyle(color: color)));

      mainWidget = Container(
        height: 34,
        child: Row(
          children: list,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        onTap();
      },
      onDoubleTap: () {
        if (onDoubleTap != null) {
          onDoubleTap!();
        }
      },
      onLongPress: () {
        if (onLongPress != null) {
          onLongPress!();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: mainWidget,
    );
  }
}
