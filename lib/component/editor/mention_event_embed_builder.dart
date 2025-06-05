import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../event/event_quote_component.dart';
import 'cust_embed_types.dart';

class MentionEventEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    var id = embedContext.node.value.data;
    return AbsorbPointer(
      child: EventQuoteComponent(id: id),
    );
  }

  @override
  String get key => CustEmbedTypes.mention_event;
}
