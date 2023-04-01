TrieTree buildTrieTree(List<List<int>> words, List<int>? skips) {
  skips ??= [];

  var tree = TrieTree(TrieNode())..skips = skips;

  for (var word in words) {
    tree.root.insertWord(word, skips);
  }

  return tree;
}

class TrieTree {
  TrieNode root;
  List<int>? skips;

  TrieTree(this.root);

  bool check(String targetStr) {
    var target = targetStr.codeUnits;
    var index = 0;
    var length = target.length;
    for (; index < length;) {
      var current = root;
      for (var i = index; i < length; i++) {
        var char = target[i];
        var tmpNode = current.find(char);
        if (tmpNode != null) {
          current = tmpNode;
          if (current.done) {
            return true;
          }
        } else {
          break;
        }
      }
      index++;
    }

    return false;
  }
}

class TrieNode {
  Map<int, TrieNode> children = {};
  bool done;

  TrieNode({
    this.done = false,
  });

  void insertWord(List<int> word, List<int> skips) {
    var current = this;
    for (var char in word) {
      current = current.findOrCreate(char, skips);
    }
    current.done = true;
  }

  TrieNode? find(int char) {
    return children[char];
  }

  TrieNode findOrCreate(int char, List<int> skips) {
    var child = children[char];
    if (child == null) {
      child = TrieNode();

      children[char] = child;
      for (var skip in skips) {
        children[skip] = child;
      }
    }
    return child;
  }
}
