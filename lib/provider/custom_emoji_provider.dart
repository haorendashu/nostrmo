// import 'dart:convert';
// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:nostrmo/provider/data_util.dart';
// import 'package:nostrmo/util/string_util.dart';

// import '../data/custom_emoji.dart';
// import '../main.dart';

// class CustomEmojiProvider extends ChangeNotifier {
//   List<CustomEmoji> emojis = [];

//   CustomEmojiProvider.load() {
//     var data = sharedPreferences.getString(DataKey.CUSTOM_EMOJI_LIST);
//     if (StringUtil.isNotBlank(data)) {
//       try {
//         var jsonMapList = jsonDecode(data!);
//         if (jsonMapList is List<dynamic>) {
//           for (var jsonMap in jsonMapList) {
//             var customEmoji = CustomEmoji.fromJson(jsonMap);
//             emojis.add(customEmoji);
//           }
//         }
//       } catch (e) {
//         log("CustomEmojiProvider.load jsonDecode error ${e.toString()}");
//       }
//     }
//   }

//   void addEmoji(CustomEmoji emoji) {
//     emojis.add(emoji);
//     emojis = [...emojis];
//     _saveAndNotify();
//   }

//   void removeEmoji(CustomEmoji emoji) {
//     emojis.remove(emoji);
//     emojis = [...emojis];
//     _saveAndNotify();
//   }

//   void _saveAndNotify() {
//     List<Map<String, dynamic>> list = [];
//     for (var emoji in emojis) {
//       list.add(emoji.toJson());
//     }
//     var data = jsonEncode(list);
//     log(data);
//     sharedPreferences.setString(DataKey.CUSTOM_EMOJI_LIST, data);
//     notifyListeners();
//   }
// }
