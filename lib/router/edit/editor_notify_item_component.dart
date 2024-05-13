import 'package:flutter/material.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

import '../../component/user/simple_name_component.dart';
import '../../consts/base.dart';

class EditorNotifyItem {
  String pubkey;

  bool selected;

  EditorNotifyItem({required this.pubkey, this.selected = true});
}

class EditorNotifyItemComponent extends StatefulWidget {
  EditorNotifyItem item;

  EditorNotifyItemComponent({required this.item});

  @override
  State<StatefulWidget> createState() {
    return _EditorNotifyItemComponent();
  }
}

class _EditorNotifyItemComponent extends State<EditorNotifyItemComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var textColor = themeData.appBarTheme.titleTextStyle!.color;

    List<Widget> list = [];
    list.add(Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      String name =
          SimpleNameComponent.getSimpleName(widget.item.pubkey, metadata);
      return Text(
        name,
        style: TextStyle(color: textColor),
      );
    }, selector: (context, _provider) {
      return _provider.getMetadata(widget.item.pubkey);
    }));

    list.add(SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: widget.item.selected,
        onChanged: (value) {
          setState(() {
            widget.item.selected = !widget.item.selected;
          });
        },
        side: BorderSide(color: textColor!.withOpacity(0.6), width: 2),
      ),
    ));

    return Container(
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.65),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: list,
        mainAxisSize: MainAxisSize.min,
      ),
      padding: EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF / 2,
        bottom: Base.BASE_PADDING_HALF / 2,
      ),
    );
  }
}
