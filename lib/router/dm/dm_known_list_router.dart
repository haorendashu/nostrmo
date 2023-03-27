import 'package:flutter/material.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';

import '../../provider/dm_provider.dart';
import 'dm_session_list_item_component.dart';

class DMKnownListRouter extends StatefulWidget {
  ECDHBasicAgreement agreement;

  DMKnownListRouter({required this.agreement});

  @override
  State<StatefulWidget> createState() {
    return _DMKnownListRouter();
  }
}

class _DMKnownListRouter extends State<DMKnownListRouter> {
  @override
  Widget build(BuildContext context) {
    var _dmProvider = Provider.of<DMProvider>(context);
    var details = _dmProvider.knownList;

    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          if (index >= details.length) {
            return null;
          }

          var detail = details[index];
          return DMSessionListItemComponent(
            detail: detail,
            agreement: widget.agreement,
          );
        },
        itemCount: details.length,
      ),
    );
  }
}
