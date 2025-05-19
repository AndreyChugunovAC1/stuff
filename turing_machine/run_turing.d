import std;

interface Tape {
  char get();
  void put(char);
  void move(int delta);
  void printState(string from, string to);
}

class GrowingTape : Tape {
  private {
    enum HALF_PRESENT_LENGTH = 20;
    enum CUR_POS = "^".center(HALF_PRESENT_LENGTH * 2 + 1);
    char[] left, right;
    int ind;
    char blank;

    ref char opIndex(int ind) {
      if (ind < 0) {
        ind = -ind - 1;
        if (to!size_t(ind) >= left.length) {
          return blank;
        }
        return left[to!size_t(ind)];
      }
      if (to!size_t(ind) >= right.length) {
        return blank;
      }
      return right[to!size_t(ind)];
    }

    void expand(ref char[] arr, size_t newLength) {
      size_t prevLength = arr.length;

      arr.length = newLength;
      arr[prevLength .. newLength] = blank;
    }
  }

  this(const(char[]) input, char blank) {
    ind = 0;
    right = input.dup;
    this.blank = blank;
  }

  char get() {
    return this[ind];
  }

  void put(char ch) {
    this[ind] = ch;
  }

  void move(int delta) {
    assert(delta >= -1 && delta <= 1);
    ind += delta;
    auto newLength = (size_t len) => (len + 1) * 3 / 2;

    if (ind >= 0 && to!size_t(ind) >= right.length) {
      expand(right, newLength(right.length));
    }
    if (ind < 0 && to!size_t(-ind - 1) >= left.length) {
      expand(left, newLength(left.length));
    }
  }

  void printState(string from, string to) {
    char[2 * HALF_PRESENT_LENGTH + 1] output;
    size_t strIndex = 0;

    foreach (i; ind - HALF_PRESENT_LENGTH .. ind + HALF_PRESENT_LENGTH + 1) {
      output[strIndex++] = this[i];
    }
    write(output);
    writefln!" :: %s -> %s"(from, to);
    writeln(CUR_POS);
  }
}

class Node {
  struct Next {
    int delta;
    char ch;
    string next;
  }

  public Next[char] next;

  override string toString() const @safe pure {
    return next.to!string;
  }
}

void main(string[] args) {
  if (args.length < 3) {
    writeln("Usage: rdmd run_turing.d <your_turing_machine> <\"your_input\">");
    return;
  }
  string root;
  bool[string] accept, reject;
  char blank;
  Node[string] nodeByName;
  bool wasError = false;

  auto inFile = File(args[1], "r");
  foreach (sPair; zip(inFile.byLine, iota!size_t(1, size_t.max))
    .filter!(s => !s[0].strip.empty)
    .filter!(s => !s[0].startsWith("//"))
    .map!(s => Tuple!(string[], size_t)(s[0].splitter.map!(to!string).array, s[1]))) {
    string[] line = sPair[0];

    switch (line[0]) {
    case "start:":
      if (line.length != 2) {
        writefln!"Incorrect \"start\" format [line: %s]"(sPair[1]);
        writeln("Format: \"start: <single_state>\"");
        wasError = true;
        break;
      }
      root = line[1];
      break;
    case "accept:":
      if (line.length < 2) {
        writefln!"Incorrect \"accept\" format [line: %s]"(sPair[1]);
        writeln("Format: \"accept: <state1> <state2> ...\"");
        wasError = true;
        break;
      }
      foreach (state; line[1 .. $]) {
        accept[state] = true;
      }
      break;
    case "reject:":
      if (line.length < 2) {
        writefln!"Incorrect \"reject\" format [line: %s]"(sPair[1]);
        writeln("Format: \"reject: <state1> <state2> ...\"");
        wasError = true;
        break;
      }
      foreach (state; line[1 .. $]) {
        reject[state] = true;
      }
      break;
    case "blank:":
      if (line.length < 2 || line[1].length > 1) {
        writefln!"Incorrect \"blank\" format [line: %s]"(sPair[1]);
        writeln("Format: \"blank: <one_symbol>\"");
        wasError = true;
        break;
      }
      blank = line[1][0];
      break;
    default:
      enum stateFormat = () {
        writeln("Format: state1 s1 -> state2 s2 <|>|^");
      };
      if (line.length != 6 || line[2] != "->") {
        writefln!"Incorrect state format [line: %s]"(sPair[1]);
      }
      string curName = line[0];
      char curChar = line[1][0];
      string nextName = line[3];
      char nextChar = line[4][0];
      int delta = 0;

      switch (line[5]) {
      case ">":
        delta = 1;
        break;
      case "<":
        delta = -1;
        break;
      case "^":
        delta = 0;
        break;
      default:
        writefln!"Incorrect move format: expected \"<\", \">\" or \"^\" [line: %s]"(sPair[1]);
        wasError = true;
        break;
      }
      Node cur = nodeByName.require(curName, new Node);
      nodeByName.require(nextName, new Node);
      cur.next[curChar] = Node.Next(delta, nextChar, nextName);
      break;
    }
  }
  inFile.close();
  if (wasError) {
    return;
  }
  Tape tape = new GrowingTape(args[2], blank);
  tape.printState("", root);
  while (root !in accept && root !in reject) {
    auto nexts = nodeByName[root].next;

    if (tape.get !in nexts) {
      tape.printState(root, reject.keys.front);
      break;
    }
    Node.Next next = nexts[tape.get];
    tape.put(next.ch);
    tape.move(next.delta);
    tape.printState(root, next.next);
    root = next.next;
  }
}
