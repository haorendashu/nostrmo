import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip02/contact.dart';
import 'package:nostr_sdk/nip02/contact_list.dart';
import 'package:provider/provider.dart';

import '../../component/user/metadata_component.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';

class UserContactListComponent extends StatefulWidget {
  ContactList contactList;

  String searchText;

  UserContactListComponent({required this.contactList, this.searchText = ""});

  @override
  State<StatefulWidget> createState() {
    return _UserContactListComponent();
  }
}

class _UserContactListComponent extends State<UserContactListComponent> {
  ScrollController _controller = ScrollController();

  List<Contact>? list;

  @override
  Widget build(BuildContext context) {
    list ??= widget.contactList.list().toList();
    var s = S.of(context);
    var metadataProvider = Provider.of<MetadataProvider>(context);
    var displayList =
        _buildDisplayList(list!, metadataProvider, widget.searchText);
    var hasNoSearchResult =
        StringUtil.isNotBlank(widget.searchText) && displayList.isEmpty;

    if (hasNoSearchResult) {
      return Center(
        child: Text(
          s.not_found,
          style: TextStyle(
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    Widget main = ListView.builder(
      controller: _controller,
      itemBuilder: (context, index) {
        var contact = displayList[index];
        return Container(
          margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
          child: Selector<MetadataProvider, Metadata?>(
            builder: (context, metadata, child) {
              return GestureDetector(
                onTap: () {
                  RouterUtil.router(
                      context, RouterPath.USER, contact.publicKey);
                },
                behavior: HitTestBehavior.translucent,
                child: MetadataComponent(
                  pubkey: contact.publicKey,
                  metadata: metadata,
                  jumpable: true,
                ),
              );
            },
            selector: (context, _provider) {
              return _provider.getMetadata(contact.publicKey);
            },
          ),
        );
      },
      itemCount: displayList.length,
    );

    if (TableModeUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return main;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Contact> _buildDisplayList(
    List<Contact> sourceList,
    MetadataProvider metadataProvider,
    String searchText,
  ) {
    var uniqueList = <Contact>[];
    var seen = <String>{};
    for (var contact in sourceList) {
      var pubkey = contact.publicKey;
      if (StringUtil.isBlank(pubkey)) {
        continue;
      }
      if (seen.add(pubkey)) {
        uniqueList.add(contact);
      }
    }

    if (StringUtil.isBlank(searchText)) {
      return uniqueList;
    }

    var keyword = searchText.toLowerCase();
    var level1 = <Contact>[];
    var level2 = <Contact>[];
    var level3 = <Contact>[];

    for (var contact in uniqueList) {
      var metadata = metadataProvider.getMetadata(contact.publicKey);
      if (metadata == null) {
        continue;
      }

      if (_matchText(metadata.name, keyword) ||
          _matchText(metadata.displayName, keyword)) {
        level1.add(contact);
      } else if (_matchText(metadata.nip05, keyword)) {
        level2.add(contact);
      } else if (_matchText(metadata.about, keyword)) {
        level3.add(contact);
      }
    }

    return [...level1, ...level2, ...level3];
  }

  bool _matchText(String? source, String keyword) {
    if (StringUtil.isBlank(source)) {
      return false;
    }

    return source!.toLowerCase().contains(keyword);
  }
}
