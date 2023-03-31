import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';

import '../../component/appbar4stack.dart';

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
      checkboxItems = [];
      checkboxItems!.add(CheckboxItem(
          "Please do not disclose or share the key to anyone.", false));
      checkboxItems!.add(CheckboxItem(
          "Nostromo developers will never require a key from you.", false));
      checkboxItems!.add(CheckboxItem(
          "Please keep the key properly for account recovery.", false));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        "Backup and Safety tips",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Text(
        "The key is a random string that resembles your account password. Anyone with this key can access and control your account.",
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
            "Copy Key",
            style: TextStyle(
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
          "Copy Hex Key",
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
        BotToast.showText(text: "Please check the tips.");
        return false;
      }
    }

    return true;
  }

  void copyHexKey() {
    if (!checkTips()) {
      return;
    }

    doCopy(nostr!.privateKey);
  }

  void copyKey() {
    if (!checkTips()) {
      return;
    }

    var pk = nostr!.privateKey;
    var nip19Key = Nip19.encodePrivateKey(pk);
    doCopy(nip19Key);
  }

  void doCopy(String key) {
    Clipboard.setData(ClipboardData(text: key)).then((_) {
      BotToast.showText(text: "key has been copy!");
    });
  }
}

class CheckboxItem {
  String name;

  bool value;

  CheckboxItem(this.name, this.value);
}
