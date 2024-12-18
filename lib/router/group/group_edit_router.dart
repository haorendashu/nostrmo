import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar4stack.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../provider/uploader.dart';
import '../../util/table_mode_util.dart';

class GroupEditRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GroupEditRouter();
  }
}

class _GroupEditRouter extends State<GroupEditRouter> {
  TextEditingController hostController = TextEditingController();
  TextEditingController groupIdController = TextEditingController();

  TextEditingController nameController = TextEditingController();
  TextEditingController pictureController = TextEditingController();
  TextEditingController aboutController = TextEditingController();

  GroupIdentifier? groupIdentifier;

  bool publicValue = false;

  bool openValue = false;

  GroupMetadata? oldGroupMetadata;

  late S s;

  @override
  Widget build(BuildContext context) {
    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    groupIdentifier = arg as GroupIdentifier;
    var margin = const EdgeInsets.only(bottom: Base.BASE_PADDING);
    var padding = const EdgeInsets.only(left: 20, right: 20);

    GroupProvider groupProvider = Provider.of<GroupProvider>(context);
    s = S.of(context);

    var groupMetadata = groupProvider.getMetadata(groupIdentifier!);

    if (groupMetadata != null) {
      if (oldGroupMetadata == null ||
          groupMetadata.groupId != oldGroupMetadata!.groupId) {
        nameController.text = getText(groupMetadata.name);
        pictureController.text = getText(groupMetadata.picture);
        aboutController.text = getText(groupMetadata.about);
        if (groupMetadata.public != null) {
          publicValue = groupMetadata.public!;
        }
        if (groupMetadata.open != null) {
          openValue = groupMetadata.open!;
        }
      }
    }
    oldGroupMetadata = groupMetadata;

    hostController.text = groupIdentifier!.host;
    groupIdController.text = groupIdentifier!.groupId;

    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var textColor = themeData.textTheme.bodyMedium!.color;

    var submitBtn = TextButton(
      onPressed: doSave,
      style: ButtonStyle(),
      child: Text(
        s.Submit,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
    );

    Color? appbarBackgroundColor = Colors.transparent;
    var appBar = Appbar4Stack(
      backgroundColor: appbarBackgroundColor,
      action: Container(
        margin: EdgeInsets.only(right: Base.BASE_PADDING),
        child: submitBtn,
      ),
    );

    List<Widget> list = [];

    if (TableModeUtil.isTableMode()) {
      list.add(Container(
        height: 30,
      ));
    }

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: hostController,
        decoration: InputDecoration(labelText: s.Relay),
        readOnly: true,
        // enabled: false,
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: groupIdController,
        decoration: InputDecoration(labelText: s.GroupId),
        readOnly: true,
        // enabled: false,
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: nameController,
        decoration: InputDecoration(labelText: s.Name),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        controller: pictureController,
        decoration: InputDecoration(
          prefixIcon: GestureDetector(
            onTap: pickPicture,
            child: Icon(Icons.image),
          ),
          labelText: s.Picture,
        ),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: TextField(
        minLines: 2,
        maxLines: 10,
        controller: aboutController,
        decoration: InputDecoration(labelText: s.About),
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: DropdownButton<bool>(
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: true,
            child: Text(s.public),
          ),
          DropdownMenuItem(
            value: false,
            child: Text(s.private),
          ),
        ],
        value: publicValue,
        onChanged: (bool? value) {
          if (value != null) {
            setState(() {
              publicValue = value;
            });
          }
        },
      ),
    ));

    list.add(Container(
      margin: margin,
      padding: padding,
      child: DropdownButton<bool>(
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: true,
            child: Text(s.open),
          ),
          DropdownMenuItem(
            value: false,
            child: Text(s.closed),
          ),
        ],
        value: openValue,
        onChanged: (bool? value) {
          if (value != null) {
            setState(() {
              openValue = value;
            });
          }
        },
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
              padding: EdgeInsets.only(
                  top: mediaDataCache.padding.top + Base.BASE_PADDING),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: list,
                ),
              ),
            ),
          ),
          Positioned(
            top: mediaDataCache.padding.top,
            left: 0,
            right: 0,
            child: Container(
              child: appBar,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> pickImageAndUpload() async {
    if (PlatformUtil.isWeb()) {
      // TODO ban image update at web temp
      return null;
    }

    var filepath = await Uploader.pick(context);
    if (StringUtil.isNotBlank(filepath)) {
      var cancelFunc = BotToast.showLoading();
      try {
        return await Uploader.upload(
          filepath!,
          imageService: settingProvider.imageService,
        );
      } finally {
        cancelFunc.call();
      }
    }
  }

  Future<void> pickPicture() async {
    var filepath = await pickImageAndUpload();
    if (StringUtil.isNotBlank(filepath)) {
      pictureController.text = filepath!;
    }
  }

  String getText(String? str) {
    return str != null ? str : "";
  }

  Future<void> doSave() async {
    GroupMetadata groupMetadata = GroupMetadata(
      groupIdentifier!.groupId,
      0,
      name: nameController.text,
      picture: pictureController.text,
      about: aboutController.text,
    );
    await groupProvider.udpateMetadata(groupIdentifier!, groupMetadata);

    if (oldGroupMetadata != null) {
      bool updateStatus = false;
      if (oldGroupMetadata!.public != publicValue) {
        updateStatus = true;
      }
      if (oldGroupMetadata!.open != openValue) {
        updateStatus = true;
      }

      if (updateStatus) {
        groupProvider.editStatus(groupIdentifier!, publicValue, openValue);
      }
    }

    RouterUtil.back(context);
  }
}
