import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';

class GroupAddDailog extends StatefulWidget {
  static Future<String?> show(BuildContext context) async {
    return await showDialog<String>(
        context: context,
        useRootNavigator: false,
        builder: (_context) {
          return GroupAddDailog();
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _GroupAddDailog();
  }
}

class _GroupAddDailog extends State<GroupAddDailog> {
  TextEditingController hostController = TextEditingController();
  TextEditingController groupIdController = TextEditingController();

  late S s;

  bool joinGroup = true;

  String crateGroupRelay = "wss://groups.0xchat.com";

  @override
  Widget build(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    List<Widget> list = [];

    list.add(Text(
      "${s.Add} ${s.Group}",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: titleFontSize,
      ),
    ));

    list.add(
      Container(
        child: Row(
          children: [
            Checkbox(
              value: joinGroup,
              onChanged: (v) {
                setState(() {
                  joinGroup = v!;
                });
              },
            ),
            Text(s.Join_Group),
            Container(
              width: Base.BASE_PADDING,
            ),
            Checkbox(
              value: !joinGroup,
              onChanged: (v) {
                setState(() {
                  joinGroup = !v!;
                });
              },
            ),
            Text(s.Create_Group),
          ],
        ),
      ),
    );

    if (joinGroup) {
      list.add(Container(
        margin: EdgeInsets.only(top: Base.BASE_PADDING),
        child: TextField(
          controller: hostController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "${s.Please_input} ${s.Relay}",
            border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
          ),
        ),
      ));
    } else {
      list.add(Container(
        margin: EdgeInsets.only(top: Base.BASE_PADDING),
        child: Row(
          children: [
            Text("${s.Relay} :  "),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: "wss://groups.0xchat.com",
                    child: Text("wss://groups.0xchat.com"),
                  ),
                  DropdownMenuItem(
                    value: "wss://relay.highlighter.com",
                    child: Text("wss://relay.highlighter.com"),
                  ),
                  // DropdownMenuItem(
                  //   value: "wss://relay.groups.nip29.com",
                  //   child: Text("wss://relay.groups.nip29.com"),
                  // ),
                  // DropdownMenuItem(
                  //   value: "wss://groups.fiatjaf.com",
                  //   child: Text("wss://groups.fiatjaf.com"),
                  // ),
                ],
                value: crateGroupRelay,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      crateGroupRelay = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ));
    }

    if (joinGroup) {
      list.add(Container(
        margin: EdgeInsets.only(top: Base.BASE_PADDING),
        child: TextField(
          controller: groupIdController,
          decoration: InputDecoration(
            hintText: "${s.Please_input} ${s.GroupId}",
            border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
          ),
        ),
      ));
    }

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

    var main = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: list,
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

  void _onConfirm() async {
    var host = hostController.text;
    var groupId = groupIdController.text;

    var cancelFunc = BotToast.showLoading();

    try {
      if (!joinGroup) {
        host = crateGroupRelay;
        groupId = StringUtil.rndNameStr(20);

        Event? event = Event(
            nostr!.publicKey,
            EventKind.GROUP_CREATE_GROUP,
            [
              ["h", groupId]
            ],
            "");
        // log(jsonEncode(event.toJson()));
        event = await nostr!
            .sendEvent(event, targetRelays: [host], tempRelays: [host]);

        // wait some time here, for relay to init this relay
        await Future.delayed(const Duration(seconds: 5));
      }

      if (StringUtil.isBlank(host) && StringUtil.isBlank(groupId)) {
        BotToast.showText(text: s.Input_can_not_be_null);
        return;
      }

      await listProvider.addGroup(GroupIdentifier(host, groupId));
    } finally {
      cancelFunc.call();
    }

    RouterUtil.back(context);
  }
}
