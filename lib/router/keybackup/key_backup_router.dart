import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';

import '../../component/appbar4stack.dart';
import '../../generated/l10n.dart';

class KeyBackupRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _KeyBackupRouter();
  }
}

class _KeyBackupRouter extends State<KeyBackupRouter> {
  bool check0 = false;
  bool check1 = false;
  bool check2 = false;

  List<CheckboxItem>? checkboxItems;

  void initCheckBoxItems(BuildContext context) {
    if (checkboxItems == null) {
      var s = S.of(context);
      checkboxItems = [];
      checkboxItems!.add(CheckboxItem(
          s.Please_do_not_disclose_or_share_the_key_to_anyone, false));
      checkboxItems!.add(CheckboxItem(
          s.Nostromo_developers_will_never_require_a_key_from_you, false));
      checkboxItems!.add(CheckboxItem(
          s.Please_keep_the_key_properly_for_account_recovery, false));
    }
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;

    initCheckBoxItems(context);

    Color? appbarBackgroundColor = Colors.transparent;
    var appBar = Appbar4Stack(
      backgroundColor: appbarBackgroundColor,
      // title: appbarTitle,
    );

    List<Widget> list = [];
    list.add(Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Text(
        s.Backup_and_Safety_tips,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Text(
        s.The_key_is_a_random_string_that_resembles_,
      ),
    ));

    for (var item in checkboxItems!) {
      list.add(checkboxView(item));
    }

    list.add(Container(
      margin: EdgeInsets.all(Base.BASE_PADDING),
      child: InkWell(
        onTap: copyKey,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: Text(
            s.Copy_Key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    list.add(Container(
      child: GestureDetector(
        onTap: copyHexKey,
        child: Text(
          s.Copy_Hex_Key,
          style: TextStyle(
            color: mainColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mediaDataCache.size.width,
            height: mediaDataCache.size.height - mediaDataCache.padding.top,
            margin: EdgeInsets.only(top: mediaDataCache.padding.top),
            child: Container(
              color: cardColor,
              child: Center(
                child: Container(
                  width: mediaDataCache.size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: list,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: mediaDataCache.padding.top,
            child: Container(
              width: mediaDataCache.size.width,
              child: appBar,
            ),
          ),
        ],
      ),
    );
  }

  Widget checkboxView(CheckboxItem item) {
    return InkWell(
      child: Row(
        children: <Widget>[
          Checkbox(
            value: item.value,
            activeColor: Colors.blue,
            onChanged: (bool? val) {
              if (val != null) {
                setState(() {
                  item.value = val;
                });
              }
            },
          ),
          Expanded(
            child: Text(
              item.name,
              maxLines: 3,
            ),
          ),
        ],
      ),
      onTap: () {
        print(item.name);
        setState(() {
          item.value = !item.value;
        });
      },
    );
  }

  bool checkTips() {
    for (var item in checkboxItems!) {
      if (!item.value) {
        BotToast.showText(text: S.of(context).Please_check_the_tips);
        return false;
      }
    }

    return true;
  }

  void copyHexKey() {
    if (!checkTips()) {
      return;
    }

    doCopy(nostr!.privateKey!);
  }

  void copyKey() {
    if (!checkTips()) {
      return;
    }

    var pk = nostr!.privateKey;
    var nip19Key = Nip19.encodePrivateKey(pk!);
    doCopy(nip19Key);
  }

  void doCopy(String key) {
    Clipboard.setData(ClipboardData(text: key)).then((_) {
      BotToast.showText(text: S.of(context).key_has_been_copy);
    });
  }
}

class CheckboxItem {
  String name;

  bool value;

  CheckboxItem(this.name, this.value);
}
