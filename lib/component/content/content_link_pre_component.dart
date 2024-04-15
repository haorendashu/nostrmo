import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:nostrmo/component/image_component.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/link_preview_data_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';

class ContentLinkPreComponent extends StatefulWidget {
  String link;

  ContentLinkPreComponent({required this.link});

  @override
  State<StatefulWidget> createState() {
    return _ContentLinkPreComponent();
  }
}

class _ContentLinkPreComponent extends State<ContentLinkPreComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    return Selector<LinkPreviewDataProvider, PreviewData?>(
      builder: (context, data, child) {
        return Container(
          margin: const EdgeInsets.all(Base.BASE_PADDING),
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: themeData.shadowColor,
                offset: const Offset(0, 0),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: LinkPreview(
            linkStyle: TextStyle(
              color: themeData.primaryColor,
              decorationColor: themeData.primaryColor,
            ),
            enableAnimation: true,
            onPreviewDataFetched: (data) {
              // Save preview data
              linkPreviewDataProvider.set(widget.link, data);
            },
            previewData: data,
            text: widget.link,
            width: mediaDataCache.size.width,
            onLinkPressed: (link) {
              WebViewRouter.open(context, link);
            },
          ),
        );
      },
      selector: (context, _provider) {
        return _provider.getPreviewData(widget.link);
      },
    );
  }
}
