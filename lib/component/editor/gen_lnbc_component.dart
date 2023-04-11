import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/zap/zap_action.dart';
import 'package:nostrmo/client/zap_num_util.dart';
import 'package:nostrmo/component/content/content_str_link_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';

class GenLnbcComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GenLnbcComponent();
  }
}

class _GenLnbcComponent extends State<GenLnbcComponent> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        var themeData = Theme.of(context);
        Color cardColor = themeData.cardColor;
        var mainColor = themeData.primaryColor;
        var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
        var s = S.of(context);
        if (metadata == null ||
            (StringUtil.isBlank(metadata.lud06) &&
                StringUtil.isBlank(metadata.lud16))) {
          return Container(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Lnurl and Lud16 can't found.",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(Base.BASE_PADDING),
                    child: ContentStrLinkComponent(
                      str: "Add now",
                      onTap: () async {
                        await RouterUtil.router(
                            context, RouterPath.PROFILE_EDITOR, metadata);
                        metadataProvider.update(nostr!.publicKey);
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        }

        List<Widget> list = [];

        list.add(Container(
          margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
          child: Text(
            "Input Sats num to gen lightning invoice",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
        ));

        list.add(Container(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Input Sats num",
              border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
            ),
          ),
        ));

        list.add(Expanded(child: Container()));

        list.add(Container(
          margin: EdgeInsets.only(
            top: Base.BASE_PADDING,
            bottom: 6,
          ),
          child: Ink(
            decoration: BoxDecoration(color: mainColor),
            child: InkWell(
              onTap: () {
                _onComfirm(metadata.pubKey!);
              },
              highlightColor: mainColor.withOpacity(0.2),
              child: Container(
                color: mainColor,
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  S.of(context).Comfirm,
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
          padding: EdgeInsets.all(Base.BASE_PADDING),
          decoration: BoxDecoration(
            color: cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        );

        return main;
      },
      selector: (context, _provider) {
        return _provider.getMetadata(nostr!.publicKey);
      },
    );
  }

  Future<void> _onComfirm(String pubkey) async {
    var text = controller.text;
    var num = int.tryParse(text);
    if (num == null) {
      BotToast.showText(text: "Number parse error");
      return;
    }

    var lnbcStr = await ZapAction.genInvoiceCode(context, num, pubkey);
    if (StringUtil.isNotBlank(lnbcStr)) {
      RouterUtil.back(context, lnbcStr);
    }
  }
}
