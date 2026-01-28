import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/cust_state.dart';
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

class _FeedBuilderRouterState extends CustState<FeedBuilderRouter> {
  var nameController = TextEditingController();

  var dataSourceValueController = TextEditingController();

  // 下拉框选项
  List<int> feedTypes = [
    FeedType.SYNC_FEED,
    FeedType.RELAYS_FEED,
    FeedType.MENTIONED_FEED
  ];
  int selectedFeedType = FeedType.SYNC_FEED;
  Map<int, String> feedTypeNameMap = {};

  int selectedDataSourceType = FeedSourceType.PUBKEY;
  Map<int, String> dataSourceTypeNameMap = {};
  List<int> selectableDataSourceType = [
    FeedSourceType.PUBKEY,
    FeedSourceType.HASH_TAG,
    FeedSourceType.FOLLOWED,
    FeedSourceType.FOLLOW_SET,
    FeedSourceType.FOLLOW_PACKS,
  ];

  List<int> eventKinds = [...EventKindType.SUPPORTED_EVENTS];
  Map<int, String> eventKindNameMap = {};

  int eventType = FeedDataEventType.EVENT_ALL;
  Map<int, String> eventTypeNameMap = {};

  List<List<dynamic>> dataSources = [];

  Naddr? followPackNaddr;

  String feedId = StringUtil.rndNameStr(14);

  late S s;

  @override
  Future<void> onReady(BuildContext context) async {
    var feedDataItf = RouterUtil.routerArgs(context);
    if (feedDataItf != null && feedDataItf is FeedData) {
      feedId = feedDataItf.id;
      selectedFeedType = feedDataItf.feedType;
      nameController.text = feedDataItf.name;
      dataSources = feedDataItf.sources;
      eventKinds = feedDataItf.eventKinds;
      eventType = feedDataItf.eventType;
      setState(() {});
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    s = S.of(context);

    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;

    var contactListProvider = Provider.of<ContactListProvider>(context);

    if (feedTypeNameMap.isEmpty) {
      feedTypeNameMap = {
        FeedType.SYNC_FEED: s.General_Feed,
        FeedType.RELAYS_FEED: s.Relay_Feed,
        FeedType.MENTIONED_FEED: s.Mentioned_Feed,
      };
    }
    if (eventKindNameMap.isEmpty) {
      eventKindNameMap = {
        EventKind.TEXT_NOTE: s.Text_Note,
        EventKind.REPOST: s.Boost,
        EventKind.GENERIC_REPOST: s.Generic_Repost,
        EventKind.PICTURE: s.Picture,
        EventKind.LONG_FORM: s.Article,
        EventKind.FILE_HEADER: s.File_Info,
        EventKind.STORAGE_SHARED_FILE: s.Storage_Shared_File,
        EventKind.TORRENTS: s.Torrents,
        EventKind.POLL: s.Poll,
        EventKind.ZAP_GOALS: s.Zap_Goals,
        EventKind.VIDEO_HORIZONTAL: s.Video_Horizontal,
        EventKind.VIDEO_VERTICAL: s.Video_Vertical,
        EventKind.COMMENT: s.Comment,
        EventKind.STARTER_PACKS: s.Starter_packs,
        EventKind.MEDIA_STARTER_PACKS: s.Media_Starter_Packs,
      };
    }
    if (dataSourceTypeNameMap.isEmpty) {
      dataSourceTypeNameMap = {
        FeedSourceType.PUBKEY: s.Pubkey,
        FeedSourceType.HASH_TAG: s.Hashtag,
        FeedSourceType.FOLLOWED: s.Followed,
        FeedSourceType.FOLLOW_SET: s.Follow_set,
        FeedSourceType.FOLLOW_PACKS: s.Starter_packs,
      };
    }
    if (eventTypeNameMap.isEmpty) {
      eventTypeNameMap = {
        FeedDataEventType.EVENT_ALL: s.All_Events,
        FeedDataEventType.EVENT_POST: s.Only_Posts,
        FeedDataEventType.EVENT_REPLY: s.Only_Replies,
      };
    }

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
        decoration: InputDecoration(labelText: s.Name),
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
        decoration: InputDecoration(
          labelText: s.Feed_Type,
          // border: OutlineInputBorder(),
        ),
        items: feedTypes.map((int value) {
          var name = feedTypeNameMap[value];
          name ??= s.Unknown;

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
        hint: Text(s.Select_a_feed_type),
      ),
    ));

    /**********************************************
     * Data Source Begin
     */
    if (selectedFeedType != FeedType.MENTIONED_FEED) {
      var valueName = dataSourceTypeNameMap[selectedDataSourceType];
      valueName ??= s.Unknown;
      if (selectedFeedType == FeedType.RELAYS_FEED) {
        valueName = s.Relay_Address;
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
            decoration: InputDecoration(
              labelText: s.Data_Source_Type,
              // border: OutlineInputBorder(),
            ),
            items: selectableDataSourceType.map((int value) {
              var name = dataSourceTypeNameMap[value];
              name ??= s.Unknown;

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
            hint: Text(s.Select_a_data_source_type),
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
                    followSet.title ?? s.Unknown,
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
                s.Add_Follow_Set,
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
                          followSet.title ?? s.Unknown,
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
        dataSourceTypeName ??= s.Unknown;
        if (selectedFeedType == FeedType.RELAYS_FEED) {
          dataSourceTypeName = s.Relay_Address;
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
                s.Data_Sources,
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
              s.Event_Kind,
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
        decoration: InputDecoration(
          labelText: s.Event_Type,
          // border: OutlineInputBorder(),
        ),
        items: eventTypeNameMap.keys.map((int value) {
          var name = eventTypeNameMap[value];
          name ??= s.Unknown;

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
        hint: Text(s.Select_a_event_type),
      ),
    ));

    list.add(Container(
      margin: twiceMargin,
      padding: padding,
      width: double.maxFinite,
      child: FilledButton(
        onPressed: saveFeed,
        child: Text(s.Save_Feed),
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Feed_Builder,
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
          eventKindNameMap[eventKind] ?? s.Unknown,
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
      BotToast.showText(text: s.Input_can_not_be_null);
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
        child: Text(s.Add_Data_Source),
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
      BotToast.showText(text: s.Please_input_the_name);
      return;
    }

    if (selectedFeedType != FeedType.MENTIONED_FEED && dataSources.isEmpty) {
      BotToast.showText(text: s.Please_add_the_data_source);
      return;
    }

    if (eventKinds.isEmpty) {
      BotToast.showText(text: s.Please_select_the_event_kind);
      return;
    }

    var feed = FeedData(
      feedId,
      name,
      selectedFeedType,
      sources: dataSources,
      eventKinds: eventKinds,
      eventType: eventType,
    );

    // feedProvider.handleFeedData(feed);
    // print(feed.datas);
    feedProvider.saveFeed(feed);

    RouterUtil.back(context);
  }
}
