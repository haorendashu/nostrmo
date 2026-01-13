import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/consts/event_kind_type.dart';
import 'package:nostrmo/consts/feed_data_event_type.dart';
import 'package:nostrmo/consts/feed_source_type.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/feed_data.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/provider/replaceable_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../consts/base.dart';
import '../../consts/feed_type.dart';
import '../../generated/l10n.dart';

class FeedBuilderRouter extends StatefulWidget {
  FeedBuilderRouter({super.key});

  @override
  State<FeedBuilderRouter> createState() => _FeedBuilderRouterState();
}

class _FeedBuilderRouterState extends State<FeedBuilderRouter> {
  var nameController = TextEditingController();

  var dataSourceValueController = TextEditingController();

  // 下拉框选项
  List<int> feedTypes = [
    FeedType.SYNC_FEED,
    FeedType.RELAYS_FEED,
    FeedType.MENTIONED_FEED
  ];
  int selectedFeedType = FeedType.SYNC_FEED;
  Map<int, String> feedTypeNameMap = {
    FeedType.SYNC_FEED: "General Feed",
    FeedType.RELAYS_FEED: "Relays Feed",
    FeedType.MENTIONED_FEED: "Mentioned Feed",
  };

  int selectedDataSourceType = FeedSourceType.PUBKEY;
  Map<int, String> dataSourceTypeNameMap = {
    FeedSourceType.PUBKEY: "Pubkey",
    FeedSourceType.HASH_TAG: "HashTag",
    FeedSourceType.FOLLOWED: "Followed",
    FeedSourceType.FOLLOW_SET: "Follow Set",
    FeedSourceType.FOLLOW_PACKS: "Follow Packs",
  };
  List<int> selectableDataSourceType = [
    FeedSourceType.PUBKEY,
    FeedSourceType.HASH_TAG,
    FeedSourceType.FOLLOWED,
    FeedSourceType.FOLLOW_SET,
    FeedSourceType.FOLLOW_PACKS,
  ];

  List<int> eventKinds = [...EventKindType.SUPPORTED_EVENTS];
  Map<int, String> eventKindNameMap = {
    EventKind.TEXT_NOTE: "Text Note",
    EventKind.REPOST: "Repost",
    EventKind.GENERIC_REPOST: "Generic Repost",
    EventKind.PICTURE: "Picture",
    EventKind.LONG_FORM: "Long Form",
    EventKind.FILE_HEADER: "File Header",
    EventKind.STORAGE_SHARED_FILE: "Storage Shared File",
    EventKind.TORRENTS: "Torrents",
    EventKind.POLL: "Poll",
    EventKind.ZAP_GOALS: "Zap Goals",
    EventKind.VIDEO_HORIZONTAL: "Video Horizontal",
    EventKind.VIDEO_VERTICAL: "Video Vertical",
    EventKind.COMMENT: "Comment",
    EventKind.STARTER_PACKS: "Starter Packs",
    EventKind.MEDIA_STARTER_PACKS: "Media Starter Packs",
  };

  int eventType = FeedDataEventType.EVENT_ALL;
  Map<int, String> eventTypeNameMap = {
    FeedDataEventType.EVENT_ALL: "All Events",
    FeedDataEventType.EVENT_POST: "Only Posts",
    FeedDataEventType.EVENT_REPLY: "Only Replies",
  };

  List<List<dynamic>> dataSources = [];

  Naddr? followPackNaddr;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;

    var contactListProvider = Provider.of<ContactListProvider>(context);

    var twiceMargin = EdgeInsets.only(bottom: Base.BASE_PADDING * 2);
    var margin = EdgeInsets.only(bottom: Base.BASE_PADDING);
    var halfMargin = EdgeInsets.only(bottom: Base.BASE_PADDING_HALF);
    var padding = EdgeInsets.only(left: 20, right: 20);

    var smallFontSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];

    /**
     * Name
     */
    list.add(Container(
      margin: twiceMargin,
      padding: padding,
      child: TextField(
        controller: nameController,
        decoration: InputDecoration(labelText: "Name"),
      ),
    ));

    /**
     * Feed Type
     */
    list.add(Container(
      margin: twiceMargin,
      padding: padding,
      child: DropdownButtonFormField<int>(
        initialValue: selectedFeedType,
        decoration: const InputDecoration(
          labelText: "Feed Type",
          // border: OutlineInputBorder(),
        ),
        items: feedTypes.map((int value) {
          var name = feedTypeNameMap[value];
          name ??= "unknown";

          return DropdownMenuItem<int>(
            value: value,
            child: Text(name),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue == FeedType.SYNC_FEED) {
            selectedDataSourceType = FeedSourceType.PUBKEY;
          } else {
            selectedDataSourceType = FeedSourceType.FEED_TYPE;
          }
          setState(() {
            selectedFeedType = newValue!;
          });
        },
        hint: Text("Select a feed type"),
      ),
    ));

    /**********************************************
     * Data Source Begin
     */
    if (selectedFeedType != FeedType.MENTIONED_FEED) {
      var valueName = dataSourceTypeNameMap[selectedDataSourceType];
      valueName ??= "unknown";
      if (selectedFeedType == FeedType.RELAYS_FEED) {
        valueName = "Relay Address";
      }
      List<Widget> dataSourcesList = [];
      if (selectedFeedType == FeedType.RELAYS_FEED) {
        dataSourcesList.add(Container(
          child: TextField(
            controller: dataSourceValueController,
            decoration: InputDecoration(labelText: valueName),
          ),
        ));
        dataSourcesList.add(buildDataSourceAddBtn());
      } else if (selectedFeedType == FeedType.SYNC_FEED) {
        dataSourcesList.add(Container(
          margin: EdgeInsets.only(top: Base.BASE_PADDING_HALF),
          child: DropdownButtonFormField<int>(
            initialValue: selectedDataSourceType,
            decoration: const InputDecoration(
              labelText: "Data Source Type",
              // border: OutlineInputBorder(),
            ),
            items: selectableDataSourceType.map((int value) {
              var name = dataSourceTypeNameMap[value];
              name ??= "unknown";

              return DropdownMenuItem<int>(
                value: value,
                child: Text(name),
              );
            }).toList(),
            onChanged: (int? newValue) {
              setState(() {
                selectedDataSourceType = newValue!;
              });
            },
            hint: Text("Select a data source type"),
          ),
        ));
      }

      if (selectedDataSourceType == FeedSourceType.PUBKEY ||
          selectedDataSourceType == FeedSourceType.HASH_TAG) {
        // pubkey or hashTag
        dataSourcesList.add(Container(
          child: TextField(
            controller: dataSourceValueController,
            decoration: InputDecoration(labelText: valueName),
          ),
        ));
        dataSourcesList.add(buildDataSourceAddBtn());
      } else if (selectedDataSourceType == FeedSourceType.FOLLOWED) {
        // followed
        dataSourcesList.add(buildDataSourceAddBtn());
      } else if (selectedDataSourceType == FeedSourceType.FOLLOW_SET) {
        // followSet
        var followSets = contactListProvider.followSetMap.values;

        List<Widget> followSetList = [];
        for (var followSet in followSets) {
          bool added = false;
          for (var dataSource in dataSources) {
            if (dataSource[0] == FeedSourceType.FOLLOW_SET &&
                dataSource[1] == NIP19Tlv.encodeNaddr(followSet.getNaddr())) {
              added = true;
              break;
            }
          }
          if (added) {
            continue;
          }

          followSetList.add(Container(
            margin: EdgeInsets.only(
              top: Base.BASE_PADDING_HALF,
            ),
            child: Row(
              children: [
                Container(
                  child: Text(
                    followSet.title ?? "unknown",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: Base.BASE_PADDING,
                    right: Base.BASE_PADDING_HALF,
                  ),
                  child: Icon(
                    Icons.people,
                    size: smallFontSize,
                  ),
                ),
                Text(
                  "${followSet.privateContacts.length} / ${followSet.publicContacts.length}",
                  style: TextStyle(
                    fontSize: smallFontSize,
                  ),
                ),
                Expanded(child: Container()),
                GestureDetector(
                  onTap: () {
                    addDataSource(FeedSourceType.FOLLOW_SET,
                        NIP19Tlv.encodeNaddr(followSet.getNaddr()));
                  },
                  child: Container(
                    child: Icon(Icons.add),
                  ),
                )
              ],
            ),
          ));
        }
        if (followSets.isEmpty) {
          dataSourcesList.add(Container(
            margin: EdgeInsets.only(
              top: Base.BASE_PADDING,
            ),
            width: double.maxFinite,
            child: FilledButton(
              onPressed: () {
                RouterUtil.router(context, RouterPath.FOLLOW_SET_LIST);
              },
              child: Text(
                "Add Follow Set",
              ),
            ),
          ));
        }
        dataSourcesList.add(Container(
          margin: EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            bottom: Base.BASE_PADDING_HALF,
          ),
          child: Column(
            children: followSetList,
          ),
        ));
      } else if (selectedDataSourceType == FeedSourceType.FOLLOW_PACKS) {
        // followPacks
        dataSourcesList.add(Container(
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                controller: dataSourceValueController,
                decoration: InputDecoration(labelText: valueName),
              )),
              Container(
                child: GestureDetector(
                  onTap: searchFollowPacks,
                  child: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ));

        if (followPackNaddr != null) {
          var aid = AId(
              kind: followPackNaddr!.kind,
              pubkey: followPackNaddr!.author,
              title: followPackNaddr!.id);

          dataSourcesList.add(Container(
            child: Selector<ReplaceableEventProvider, Event?>(
              builder: (context, event, child) {
                if (event == null) {
                  return Container();
                }

                var followSet = FollowSet.getPublicFollowSet(event);
                return Container(
                  margin: const EdgeInsets.only(
                    top: Base.BASE_PADDING,
                    bottom: Base.BASE_PADDING,
                  ),
                  child: Row(
                    children: [
                      Container(
                        child: Text(
                          followSet.title ?? "unknown",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          left: Base.BASE_PADDING,
                          right: Base.BASE_PADDING_HALF,
                        ),
                        child: Icon(
                          Icons.people,
                          size: smallFontSize,
                        ),
                      ),
                      Text(
                        "${followSet.publicContacts.length}",
                        style: TextStyle(
                          fontSize: smallFontSize,
                        ),
                      ),
                      Expanded(child: Container()),
                      GestureDetector(
                        onTap: () {
                          addDataSource(FeedSourceType.FOLLOW_PACKS,
                              NIP19Tlv.encodeNaddr(followPackNaddr!));
                          followPackNaddr = null;
                        },
                        child: Container(
                          child: Icon(Icons.add),
                        ),
                      )
                    ],
                  ),
                );
              },
              selector: (context, _provider) {
                return _provider.getEvent(aid, relays: followPackNaddr!.relays);
              },
            ),
          ));
        }
      }

      /**
     * Added Data Source Widgets
     */
      List<Widget> addedDataSourceWidgets = [];
      for (var dataSource in dataSources) {
        if (dataSource.length < 2) {
          continue;
        }

        var dataSourceType = dataSource[0];
        var dataSourceValue = dataSource[1];
        var dataSourceTypeName = dataSourceTypeNameMap[dataSourceType];
        dataSourceTypeName ??= "unknown";
        if (selectedFeedType == FeedType.RELAYS_FEED) {
          dataSourceTypeName = "Relay Address";
        }
        String text = dataSourceTypeName;
        List<Widget> singleDsWidgetList = [
          Text(text),
        ];
        if (dataSourceType == FeedSourceType.FOLLOW_SET) {
          String? title;
          var naddr = NIP19Tlv.decodeNaddr(dataSourceValue);
          if (naddr != null && StringUtil.isNotBlank(naddr.id)) {
            var followSet = contactListProvider.followSetMap[naddr.id];
            if (followSet != null) {
              title = followSet.title;
            }
          }
          singleDsWidgetList
              .add(Expanded(child: Text(": ${title ?? dataSourceValue}")));
        } else if (dataSourceType == FeedSourceType.FOLLOW_PACKS) {
          String? title;
          var naddr = NIP19Tlv.decodeNaddr(dataSourceValue);
          if (naddr != null && StringUtil.isNotBlank(naddr.id)) {
            var aid =
                AId(kind: naddr.kind, pubkey: naddr.author, title: naddr.id);
            var event =
                replaceableEventProvider.getEvent(aid, relays: naddr.relays);
            if (event != null && event.kind == EventKind.STARTER_PACKS) {
              var followSet = FollowSet.getPublicFollowSet(event);
              title = followSet.title;
            }
          }
          singleDsWidgetList
              .add(Expanded(child: Text(": ${title ?? dataSourceValue}")));
        } else {
          if (StringUtil.isNotBlank(dataSourceValue)) {
            singleDsWidgetList.add(Expanded(
                child: Text(
              ": $dataSourceValue",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )));
          } else {
            singleDsWidgetList.add(Expanded(child: Container()));
          }
        }
        singleDsWidgetList.add(GestureDetector(
          onTap: () {
            setState(() {
              dataSources.remove(dataSource);
            });
          },
          child: Container(
            child: Icon(Icons.delete),
          ),
        ));

        addedDataSourceWidgets.add(Container(
          margin: halfMargin,
          child: Row(
            children: singleDsWidgetList,
          ),
        ));
      }

      list.add(Container(
        margin: twiceMargin,
        alignment: Alignment.centerLeft,
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: halfMargin,
              child: Text(
                "Data Sources",
                // style: TextStyle(color: hintColor),
              ),
            ),
            Container(
              margin: margin,
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
                top: Base.BASE_PADDING_HALF,
                bottom: Base.BASE_PADDING_HALF,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: hintColor,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: dataSourcesList,
              ),
            ),
            Column(
              children: addedDataSourceWidgets,
            ),
          ],
        ),
      ));
    }
    /**
     * Data Source End
     *****************************************************************
     */

    List<Widget> eventKindWidgets = [];
    for (var eventKind in EventKindType.SUPPORTED_EVENTS) {
      if (eventKinds.contains(eventKind)) {
        // selectd !
        eventKindWidgets.add(buildEventKindWidget(eventKind, true, themeData));
      } else {
        eventKindWidgets.add(buildEventKindWidget(eventKind, false, themeData));
      }
    }
    double eventKindSelectorHeight = 40;
    list.add(Container(
      margin: twiceMargin,
      alignment: Alignment.centerLeft,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // margin: EdgeInsets.only(left: 3),
            child: Text(
              "Event Kind",
              // style: TextStyle(color: hintColor),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: Base.BASE_PADDING,
            ),
            constraints: BoxConstraints(
              minHeight: eventKindSelectorHeight,
            ),
            child: Wrap(
              spacing: Base.BASE_PADDING,
              runSpacing: Base.BASE_PADDING,
              children: eventKindWidgets,
            ),
          ),
        ],
      ),
    ));

    list.add(Container(
      margin: twiceMargin,
      padding: padding,
      child: DropdownButtonFormField<int>(
        initialValue: eventType,
        decoration: const InputDecoration(
          labelText: "Event Type",
          // border: OutlineInputBorder(),
        ),
        items: eventTypeNameMap.keys.map((int value) {
          var name = eventTypeNameMap[value];
          name ??= "unknown";

          return DropdownMenuItem<int>(
            value: value,
            child: Text(name),
          );
        }).toList(),
        onChanged: (int? newValue) {
          setState(() {
            eventType = newValue!;
          });
        },
        hint: Text("Select a event type"),
      ),
    ));

    list.add(Container(
      margin: twiceMargin,
      padding: padding,
      width: double.maxFinite,
      child: FilledButton(
        onPressed: saveFeed,
        child: Text("Save Feed"),
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          "Feed Builder",
          style: TextStyle(
            fontSize: themeData.textTheme.bodyLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        ),
      ),
    );
  }

  Widget buildEventKindWidget(
      int eventKind, bool isSelected, ThemeData themeData) {
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          eventKinds.remove(eventKind);
        } else {
          if (!eventKinds.contains(eventKind)) {
            eventKinds.add(eventKind);
          }
        }
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
          top: 2,
          bottom: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? themeData.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          eventKindNameMap[eventKind] ?? "unknown",
          style: TextStyle(
            color: isSelected ? Colors.white : themeData.hintColor,
            fontSize: themeData.textTheme.bodySmall!.fontSize,
          ),
        ),
      ),
    );
  }

  void addDataSource(int? dataSourceType, String? value) {
    value ??= dataSourceValueController.text;
    dataSourceValueController.clear();
    dataSourceType ??= selectedDataSourceType;

    if (selectedFeedType == FeedType.RELAYS_FEED) {
      dataSourceType = FeedSourceType.FEED_TYPE;
    }
    if (dataSourceType == FeedSourceType.FOLLOWED) {
      value = "";
    }

    if (dataSourceType != FeedSourceType.FOLLOWED &&
        StringUtil.isBlank(value)) {
      BotToast.showText(text: 'Please input the text');
      return;
    }

    for (var source in dataSources) {
      if (source.length <= 1) {
        continue;
      }

      if (source[0] == dataSourceType && source[1] == value) {
        // already added
        return;
      }
    }

    dataSources.add([dataSourceType, value]);
    setState(() {});
  }

  Widget buildDataSourceAddBtn() {
    return Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING_HALF,
      ),
      width: double.infinity,
      child: FilledButton(
        onPressed: () => addDataSource(null, null),
        child: Text("Add Data Source"),
      ),
    );
  }

  void searchFollowPacks() {
    var value = dataSourceValueController.text;
    if (selectedDataSourceType == FeedSourceType.FOLLOW_PACKS &&
        StringUtil.isNotBlank(value) &&
        NIP19Tlv.isNaddr(value)) {
      followPackNaddr = NIP19Tlv.decodeNaddr(value);
      if (followPackNaddr != null) {
        dataSourceValueController.clear();
      }
      setState(() {});
    }
  }

  void saveFeed() {
    var name = nameController.text;

    if (StringUtil.isBlank(name)) {
      BotToast.showText(text: 'Please input the name');
      return;
    }

    if (selectedFeedType != FeedType.MENTIONED_FEED && dataSources.isEmpty) {
      BotToast.showText(text: 'Please add the data source');
      return;
    }

    if (eventKinds.isEmpty) {
      BotToast.showText(text: 'Please select the event kind');
      return;
    }

    var feed = FeedData(
      StringUtil.rndNameStr(14),
      name,
      selectedFeedType,
      sources: dataSources,
      eventKinds: eventKinds,
      eventType: eventType,
    );

    // feedProvider.handleFeedData(feed);
    // print(feed.datas);
    feedProvider.saveFeed(feed);
  }
}
