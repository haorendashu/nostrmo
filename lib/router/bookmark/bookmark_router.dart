import 'package:flutter/material.dart';
import 'package:nostrmo/client/aid.dart';
import 'package:nostrmo/client/nip51/bookmarks.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

import '../../component/content/content_link_pre_component.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_quote_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../provider/setting_provider.dart';
import '../../util/platform_util.dart';
import '../../util/router_util.dart';
import '../index/index_app_bar.dart';

class BookmarkRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BookmarkRouter();
  }
}

class _BookmarkRouter extends CustState<BookmarkRouter> {
  @override
  Widget doBuild(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    var themeData = Theme.of(context);
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (PlatformUtil.isTableMode()) {
      indicatorColor = themeData.primaryColor;
    }
    var s = S.of(context);

    var main =
        Selector<ListProvider, Bookmarks>(builder: (context, bookmarks, child) {
      return Container(
        child: TabBarView(
          children: [
            buildBookmarkItems(bookmarks.privateItems),
            buildBookmarkItems(bookmarks.publicItems),
          ],
        ),
      );
    }, selector: (context, _provider) {
      return _provider.getBookmarks();
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              RouterUtil.back(context);
            },
            child: Icon(
              Icons.arrow_back_ios,
              color: themeData.appBarTheme.titleTextStyle!.color,
            ),
          ),
          title: TabBar(
            indicatorColor: indicatorColor,
            indicatorWeight: 3,
            tabs: [
              Container(
                height: IndexAppBar.height,
                alignment: Alignment.center,
                child: Text(
                  s.Private,
                  style: titleTextStyle,
                ),
              ),
              Container(
                height: IndexAppBar.height,
                alignment: Alignment.center,
                child: Text(
                  s.Public,
                  style: titleTextStyle,
                ),
              )
            ],
          ),
        ),
        body: main,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  Widget buildBookmarkItems(List<BookmarkItem> items) {
    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          var item = items[items.length - index - 1];
          if (item.key == "r") {
            return Container(
              child: ContentLinkPreComponent(
                link: item.value,
              ),
            );
          } else {
            return Container(
              child: EventQuoteComponent(
                id: item.key == "e" ? item.value : null,
                aId: item.key == "a" ? AId.fromString(item.value) : null,
              ),
            );
          }
        },
        itemCount: items.length,
      ),
    );
  }
}
