import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip47/nwc_info.dart';
import 'package:nostrmo/component/appbar_back_btn_component.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/nwc/nwc_setting_body_component.dart';
import 'package:nostrmo/util/colors_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../util/table_mode_util.dart';

class NwcSettingRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NwcSettingRouter();
  }
}

class _NwcSettingRouter extends State<NwcSettingRouter> {
  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          "NWC ${s.Setting}",
          style: TextStyle(
            fontSize: themeData.textTheme.bodyLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: NwcSettingBodyComponent(),
    );
  }
}
