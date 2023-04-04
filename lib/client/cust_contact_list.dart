import 'package:nostr_dart/nostr_dart.dart';

class CustContactList {
  final Map<String, Contact> _contacts;

  CustContactList() : _contacts = {};

  factory CustContactList.fromJson(List<dynamic> tags) {
    Map<String, Contact> contacts = {};
    for (List<dynamic> tag in tags) {
      String url = "";
      String petname = "";
      var length = tag.length;
      if (length > 2) {
        url = tag[2];
      }
      if (length > 3) {
        petname = tag[3];
      }
      final contact = Contact(publicKey: tag[1], url: url, petname: petname);
      contacts[contact.publicKey] = contact;
    }
    return CustContactList._(contacts);
  }

  CustContactList._(Map<String, Contact> contacts) : _contacts = contacts;

  List<dynamic> toJson() {
    List<dynamic> result = [];
    for (Contact contact in _contacts.values) {
      result.add(["p", contact.publicKey, contact.url, contact.petname]);
    }
    return result;
  }

  void add(Contact contact) {
    _contacts[contact.publicKey] = contact;
  }

  Contact? get(String publicKey) {
    return _contacts[publicKey];
  }

  Contact? remove(String publicKey) {
    return _contacts.remove(publicKey);
  }

  Iterable<Contact> list() {
    return _contacts.values;
  }

  bool isEmpty() {
    return _contacts.isEmpty;
  }

  void clear() {
    _contacts.clear();
  }
}
