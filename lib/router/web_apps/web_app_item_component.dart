import 'package:flutter/material.dart';

import '../../consts/base.dart';
import 'web_app_item.dart';

class WebAppItemComponent extends StatefulWidget {
  WebAppItem item;

  Function(WebAppItem item)? onTap;

  WebAppItemComponent(
    this.item, {
    this.onTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _WebAppItemComponent();
  }
}

class _WebAppItemComponent extends State<WebAppItemComponent> {
  double IMAGE_WIDTH = 74;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          print("onTap!!");
          widget.onTap!(widget.item);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING,
        ),
        child: Row(
          children: [
            Container(
              height: IMAGE_WIDTH,
              width: IMAGE_WIDTH,
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: widget.item.image != null
                  ? Image.network(
                      widget.item.image!,
                      height: IMAGE_WIDTH,
                      width: IMAGE_WIDTH,
                    )
                  : Icon(
                      Icons.public,
                      size: 70,
                    ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: Base.BASE_PADDING),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Text(
                        widget.item.name,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      child: Text(
                        widget.item.desc,
                        style: TextStyle(
                          color: themeData.hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
