import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/nip02/contact.dart';
import '../../client/nip02/cust_contact_list.dart';
import '../../component/user/metadata_component.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/platform_util.dart';
import '../../util/router_util.dart';

class UserContactListComponent extends StatefulWidget {
  CustContactList contactList;

  UserContactListComponent({required this.contactList});

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

    Widget main = ListView.builder(
      controller: _controller,
      itemBuilder: (context, index) {
        var contact = list![index];
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
                  pubKey: contact.publicKey,
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
      itemCount: list!.length,
    );

    if (PlatformUtil.isTableMode()) {
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
}
