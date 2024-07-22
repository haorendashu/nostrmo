import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/util/string_util.dart';

import '../event.dart';
import 'group_object.dart';

class GroupAdmins extends GroupObject {
  List<GroupAdminUser> users;

  GroupAdmins(String groupId, int createdAt, this.users)
      : super(groupId, createdAt);

  GroupAdminUser? contains(String pubkey) {
    for (var u in users) {
      if (u.pubkey == pubkey) {
        return u;
      }
    }

    return null;
  }

  static GroupAdmins? loadFromEvent(Event e) {
    if (e.kind != EventKind.GROUP_ADMINS) {
      return null;
    }

    String? groupId;
    List<GroupAdminUser> users = [];
    for (var tag in e.tags) {
      if (tag is List) {
        var length = tag.length;
        if (length > 1) {
          var key = tag[0];
          var value = tag[1];

          if (key == "d") {
            groupId = value;
          } else if (key == "p") {
            String? role;
            List<String>? permissions;
            if (length > 2) {
              role = tag[2];
            }
            if (length > 3) {
              permissions = [];
              for (var i = 3; i < length; i++) {
                var permission = tag[i];
                permissions.add(permission);
              }
            }

            var user = GroupAdminUser(
                pubkey: value, role: role, permissions: permissions);
            users.add(user);
          }
        }
      }
    }

    if (StringUtil.isBlank(groupId)) {
      return null;
    }

    return GroupAdmins(groupId!, e.createdAt, users);
  }
}

class GroupAdminUser {
  String? pubkey;

  String? role;

  List<String>? permissions;

  GroupAdminUser({
    this.pubkey,
    this.role,
    this.permissions,
  });
}
