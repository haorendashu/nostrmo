import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/nwc_transaction.dart';

class WalletTransactionComponent extends StatelessWidget {
  final NwcTransaction transaction;

  WalletTransactionComponent(this.transaction, {super.key});

  @override
  Widget build(BuildContext context) {
    var settledAtStr = "";
    if (transaction.settledAt != null) {
      var settledAt =
          DateTime.fromMillisecondsSinceEpoch(transaction.settledAt! * 1000);
      settledAtStr =
          "${settledAt.year}-${settledAt.month}-${settledAt.day} ${settledAt.hour}:${settledAt.minute}:${settledAt.second}";
    }

    String description = StringUtil.isNotBlank(transaction.description)
        ? transaction.description!
        : (isIncoming ? "Received" : "Sent");

    return Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Row(
        children: [
          Container(
            child: isIncoming
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.green,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      Icons.arrow_upward,
                      color: Colors.orange,
                    ),
                  ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
            ),
            width: 50,
            height: 50,
            clipBehavior: Clip.hardEdge,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(settledAtStr),
                ],
              ),
            ),
          ),
          Container(
            child: Column(
              children: [
                Text(
                  "${isIncoming ? "+" : "-"} ${(transaction.amount! / 1000).toInt().toString()} sats",
                  style: TextStyle(
                    color: isIncoming ? Colors.green : Colors.orange,
                  ),
                ),
                Text(""),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get isIncoming => transaction.type == "incoming";
}
