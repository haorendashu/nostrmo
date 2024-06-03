// Using a trie to match some text from content
import 'package:nostrmo/component/content/trie_text_matcher/target_text_type.dart';

class TrieTextMatcher {
  TrieTextMatcherNode root = TrieTextMatcherNode();

  void addNodes(int textType, List<dynamic> nodes, {bool allowNoArg = false}) {
    var current = root;
    for (var node in nodes) {
      if (node == true) {
        // arg nodes
        current.isArg = true;
      } else if (node is int) {
        current = current.findOrCreate(node);
      }
    }

    current.textType = textType;
    current.done = true;
    current.allowNoArg = allowNoArg;
  }

  TrieTextMatchResult check(List<int> source) {
    TrieTextMatchResult result = TrieTextMatchResult();

    var start = 0;
    var length = source.length;

    List<TrieTextMatchResultItem> args = [];

    for (; start < length;) {
      var current = root;

      int? textType;

      int index = start;
      int? argStart;
      for (; index < length; index++) {
        var char = source[index];
        var tmpNode = current.find(char);
        if (tmpNode != null) {
          var isArg = (tmpNode == current && current.isArg);
          current = tmpNode;
          if (!isArg &&
              current.done &&
              (args.isNotEmpty || argStart != null || current.allowNoArg)) {
            textType = current.textType;

            if (argStart != null) {
              // there is some arg before, add arg to args
              args.add(TrieTextMatchResultItem(
                  TargetTextType.PURE_TEXT, argStart, index - 1));
              argStart = null;
            }
            break;
          } else if (isArg) {
            // this chat is part of arg
            argStart ??= index;
          } else {
            // this chat is part of delimiter, check if there is arg before
            if (argStart != null) {
              // there is some arg before, add arg to args
              args.add(TrieTextMatchResultItem(
                  TargetTextType.PURE_TEXT, argStart, index - 1));
              argStart = null;
            }
          }
        } else {
          break;
        }
      }
      argStart = null;

      if (textType != null) {
        // find a complete textType
        result.items
            .add(TrieTextMatchResultItem(textType, start, index)..args = args);
        start = index + 1;
        args = [];
        continue;
      } else {
        // can't find other textType, this type is pure text
        if (result.items.isNotEmpty &&
            result.items.last.textType == TargetTextType.PURE_TEXT) {
          // add to the last
          result.items.last.end = start;
        } else {
          // add a new pure text item
          result.items.add(
              TrieTextMatchResultItem(TargetTextType.PURE_TEXT, start, start));
        }

        if (args.isNotEmpty) {
          args = [];
        }
      }

      start++;
    }

    return result;
  }
}

class TrieTextMatcherNode {
  Map<int, TrieTextMatcherNode> children = {};
  bool done;
  bool isArg;
  bool allowNoArg;
  int? textType;

  TrieTextMatcherNode({
    this.done = false,
    this.isArg = false,
    this.allowNoArg = false,
  });

  TrieTextMatcherNode? find(int char) {
    var childNode = children[char];
    if (childNode != null) {
      return childNode;
    } else if (isArg) {
      return this;
    }

    return null;
  }

  TrieTextMatcherNode findOrCreate(int char) {
    var child = children[char];
    if (child == null) {
      child = TrieTextMatcherNode();
      children[char] = child;
    }
    return child;
  }
}

class TrieTextMatchResult {
  List<TrieTextMatchResultItem> items = [];
}

class TrieTextMatchResultItem {
  int textType;

  // include
  int start;

  // include
  int end;

  List<TrieTextMatchResultItem> args = [];

  TrieTextMatchResultItem(this.textType, this.start, this.end);
}
