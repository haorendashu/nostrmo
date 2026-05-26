import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip02/contact_list.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import 'user_contact_list_component.dart';

class UserContactListRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserContactListRouter();
  }
}

class _UserContactListRouter extends State<UserContactListRouter> {
  ContactList? contactList;

  TextEditingController searchController = TextEditingController();

  FocusNode searchFocusNode = FocusNode();

  String searchText = "";

  bool showSearchInput = false;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);

    if (contactList == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as ContactList;
      }
    }
    if (contactList == null) {
      RouterUtil.back(context);
      return Container();
    }
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Following,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                showSearchInput = true;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  searchFocusNode.requestFocus();
                }
              });
            },
            child: Container(
              padding: EdgeInsets.only(right: Base.BASE_PADDING),
              child: Icon(
                Icons.search,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showSearchInput)
            Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
                top: Base.BASE_PADDING,
                bottom: Base.BASE_PADDING_HALF,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: s.Please_input_search_content,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) {
                        setState(() {
                          searchText = v.trim();
                        });
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      searchFocusNode.unfocus();
                      searchController.clear();
                      setState(() {
                        searchText = "";
                        showSearchInput = false;
                      });
                    },
                    child: Text(s.Cancel),
                  ),
                ],
              ),
            ),
          Expanded(
            child: UserContactListComponent(
              contactList: contactList!,
              searchText: searchText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}
