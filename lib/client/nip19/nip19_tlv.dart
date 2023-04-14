import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:hex/hex.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/nip19/tlv_util.dart';

import '../../component/content/content_decoder.dart';
import 'hrps.dart';

class NIP19Tlv {
  static bool isNprofile(String text) {
    return Nip19.isKey(Hrps.NPROFILE, text);
  }

  static bool isNevent(String text) {
    return Nip19.isKey(Hrps.NEVENT, text);
  }

  static bool isNrelay(String text) {
    return Nip19.isKey(Hrps.NRELAY, text);
  }

  static bool isNaddr(String text) {
    return Nip19.isKey(Hrps.NADDR, text);
  }

  static List<int> _decodePreHandle(String text) {
    try {
      text = text.replaceAll(ContentDecoder.NOTE_REFERENCES, "");

      var decoder = Bech32Decoder();
      var bech32Result = decoder.convert(text, 1000);
      var buf = Nip19.convertBits(bech32Result.data, 5, 8, false);

      return buf;
    } catch (e) {
      return [];
    }
  }

  static Nprofile? decodeNprofile(String text) {
    List<int> buf = _decodePreHandle(text);

    String? pubkey;
    List<String> relays = [];

    int startIndex = 0;
    while (true) {
      var tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        pubkey = HEX.encode(tlvData.data);
      } else if (tlvData.typ == TLVType.Relay) {
        var relay = utf8.decode(tlvData.data);
        relays.add(relay);
      }
    }

    if (pubkey != null) {
      return Nprofile(pubkey: pubkey, relays: relays);
    }

    return null;
  }

  static Nevent? decodeNevent(String text) {
    List<int> buf = _decodePreHandle(text);

    String? id;
    List<String> relays = [];
    String? author;

    int startIndex = 0;
    while (true) {
      var tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        id = HEX.encode(tlvData.data);
      } else if (tlvData.typ == TLVType.Relay) {
        var relay = utf8.decode(tlvData.data);
        relays.add(relay);
      } else if (tlvData.typ == TLVType.Author) {
        author = HEX.encode(tlvData.data);
      }
    }

    if (id != null) {
      return Nevent(id: id, relays: relays, author: author);
    }

    return null;
  }

  static Nrelay? decodeNrelay(String text) {
    List<int> buf = _decodePreHandle(text);

    String? addr;

    int startIndex = 0;
    while (true) {
      var tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        var relay = utf8.decode(tlvData.data);
        addr = relay;
      }
    }

    if (addr != null) {
      return Nrelay(addr);
    }

    return null;
  }

  static Naddr? decodeNaddr(String text) {
    List<int> buf = _decodePreHandle(text);

    String? id;
    String? author;
    int? kind;
    List<String> relays = [];

    int startIndex = 0;
    while (true) {
      var tlvData = TLVUtil.readTLVEntry(buf, startIndex: startIndex);
      if (tlvData == null) {
        break;
      }
      startIndex += tlvData.length + 2;

      if (tlvData.typ == TLVType.Default) {
        id = HEX.encode(tlvData.data);
      } else if (tlvData.typ == TLVType.Relay) {
        var relay = utf8.decode(tlvData.data);
        relays.add(relay);
      } else if (tlvData.typ == TLVType.Kind) {
        kind = tlvData.data[0];
      } else if (tlvData.typ == TLVType.Author) {
        author = HEX.encode(tlvData.data);
      }
    }

    if (id != null && author != null && kind != null) {
      return Naddr(id: id, author: author, kind: kind, relays: relays);
    }

    return null;
  }

  static String _handleEncodeResult(String hrp, List<int> buf) {
    var encoder = Bech32Encoder();
    Bech32 input = Bech32(hrp, buf);
    return ContentDecoder.NOTE_REFERENCES + encoder.convert(input);
  }

  static String encodeNprofile(Nprofile o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.pubkey));
    if (o.relays != null) {
      for (var relay in o.relays!) {
        TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
      }
    }

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NPROFILE, buf);
  }

  static String encodeNevent(Nevent o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.id));
    if (o.relays != null) {
      for (var relay in o.relays!) {
        TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
      }
    }
    if (o.author != null) {
      TLVUtil.writeTLVEntry(buf, TLVType.Author, utf8.encode(o.author!));
    }

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NEVENT, buf);
  }

  static String encodeNrelay(Nrelay o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, utf8.encode(o.addr));

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NRELAY, buf);
  }

  static String encodeNaddr(Naddr o) {
    List<int> buf = [];
    TLVUtil.writeTLVEntry(buf, TLVType.Default, HEX.decode(o.id));
    TLVUtil.writeTLVEntry(buf, TLVType.Author, HEX.decode(o.author));
    TLVUtil.writeTLVEntry(buf, TLVType.Kind, [o.kind]);
    if (o.relays != null) {
      for (var relay in o.relays!) {
        TLVUtil.writeTLVEntry(buf, TLVType.Relay, utf8.encode(relay));
      }
    }

    buf = Nip19.convertBits(buf, 8, 5, true);

    return _handleEncodeResult(Hrps.NRELAY, buf);
  }
}

class Nprofile {
  String pubkey;

  List<String>? relays;

  Nprofile({required this.pubkey, this.relays});
}

class Nevent {
  String id;

  List<String>? relays;

  String? author;

  Nevent({required this.id, this.relays, this.author});
}

class Nrelay {
  String addr;

  Nrelay(this.addr);
}

class Naddr {
  String id;

  String author;

  int kind;

  List<String>? relays;

  Naddr({
    required this.id,
    required this.author,
    required this.kind,
    this.relays,
  });
}
