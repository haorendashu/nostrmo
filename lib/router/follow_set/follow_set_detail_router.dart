import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip02/contact.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/nip51/follow_set.dart';
import 'package:nostrmo/component/user/simple_metadata_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';

import '../../consts/router_path.dart';
import '../../util/platform_util.dart';
import '../../util/router_util.dart';
import '../index/index_app_bar.dart';

class FollowSetDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FollowSetDetailRouter();
  }
}

class _FollowSetDetailRouter extends State<FollowSetDetailRouter> {
  FollowSet? followSet;

  late S s;

  @override
  Widget build(BuildContext context) {
    var followSetItf = RouterUtil.routerArgs(context);
    if (followSetItf == null || followSetItf is! FollowSet) {
      RouterUtil.back(context);
      return Container();
    }
    followSet = followSetItf;

    s = S.of(context);
    var themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (PlatformUtil.isTableMode()) {
      indicatorColor = themeData.primaryColor;
    }

    var main = Container(
      child: TabBarView(
        children: [
          buildContacts(
              followSet!.privateContacts, privateController, addPrivate),
          buildContacts(followSet!.publicContacts, publicController, addPublic),
        ],
      ),
    );

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

  TextEditingController privateController = TextEditingController();

  TextEditingController publicController = TextEditingController();

  void addPrivate() {
    var pubkey = getPlainPubkey(privateController);
    Contact contact = Contact(publicKey: pubkey);
    followSet!.addPrivate(contact);

    privateController.clear();
    contactListProvider.addFollowSet(followSet!);
    setState(() {});
  }

  void addPublic() {
    var pubkey = getPlainPubkey(publicController);
    Contact contact = Contact(publicKey: pubkey);
    followSet!.addPublic(contact);

    publicController.clear();
    contactListProvider.addFollowSet(followSet!);
    setState(() {});
  }

  String getPlainPubkey(TextEditingController controller) {
    var text = controller.text;
    if (Nip19.isPubkey(text)) {
      return Nip19.decode(text);
    }

    return text;
  }

  buildContacts(List<Contact> contacts, TextEditingController controller,
      VoidCallback onTap) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
            child: ListView.builder(
              itemBuilder: (context, index) {
                var contact = contacts[contacts.length - index - 1];
                return Container(
                  margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      RouterUtil.router(
                          context, RouterPath.USER, contact.publicKey);
                    },
                    child: SimpleMetadataComponent(
                      pubkey: contact.publicKey,
                    ),
                  ),
                );
              },
              itemCount: contacts.length,
            ),
          ),
        ),
        Container(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person),
              hintText: s.Please_input_user_pubkey,
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
                onPressed: onTap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
