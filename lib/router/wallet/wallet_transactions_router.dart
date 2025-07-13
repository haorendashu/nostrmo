import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/data/nwc_transaction.dart';
import 'package:nostrmo/main.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';
import 'wallet_transaction_component.dart';

class WalletTransactionsRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WalletTransactionsRouter();
  }
}

class _WalletTransactionsRouter extends CustState<WalletTransactionsRouter> {
  late S s;

  @override
  Future<void> onReady(BuildContext context) async {
    load();
  }

  int? until = (DateTime.now().millisecondsSinceEpoch / 1000).toInt();

  List<NwcTransaction> allTransactions = [];

  void load() {
    nwcProvider.queryTransactions(
      until: until,
      onTransactions: (transactions) {
        allTransactions.addAll(transactions);
        allTransactions.sort((a, b) {
          if (b.createdAt != null && a.createdAt != null) {
            return b.createdAt!.compareTo(a.createdAt!);
          }

          return 0;
        });

        if (allTransactions.isNotEmpty) {
          until = allTransactions.last.createdAt;
        }

        setState(() {});
      },
    );
  }

  @override
  Widget doBuild(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];
    for (var transaction in allTransactions) {
      list.add(WalletTransactionComponent(transaction));
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Last_Transactions,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: list,
        ),
      ),
    );
  }
}
