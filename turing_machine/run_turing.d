import std;

class Line {
  private {
    enum HALF_LINE_LENGTH = 1000;
    enum HALF_PRESENT_LENGTH = 20;
    enum CUR_POS = "^".center(2 * HALF_PRESENT_LENGTH + 1);
    char[HALF_LINE_LENGTH * 2] line;
    int ind = HALF_LINE_LENGTH;
  }

  this(string input, char blank = '_') {
    line[] = blank;
    foreach (i, ch; input) {
      line[ind + i] = ch;
    }
  }

  char get() {
    return line[ind];
  }

  void move(int delta) {
    assert(abs(delta) <= 1);
    ind += delta;
  }

  void put(char ch) {
    line[ind] = ch;
  }

  void printStateCentered(string from, string to) {
    writeln(line[ind - HALF_PRESENT_LENGTH .. ind + HALF_PRESENT_LENGTH]);
    writeln(CUR_POS);
  }

  void printState(string from, string to) {
    // printStateCentered(from, to);
    write(line[HALF_LINE_LENGTH - HALF_PRESENT_LENGTH .. HALF_LINE_LENGTH + HALF_PRESENT_LENGTH + 1]);
    writefln!" :: %s -> %s"(from, to);
    if (ind + HALF_PRESENT_LENGTH > HALF_LINE_LENGTH) {
      writeln(' '.repeat(ind + HALF_PRESENT_LENGTH - HALF_LINE_LENGTH).array ~ "^");
    } else {
      writeln();
    }
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
  string root, accept, reject;
  char blank;
  Node[string] nodeByName;

  auto inFile = File(args[1], "r");
  inFile.byLine
    .filter!(s => !s.strip.empty)
    .filter!(s => !s.startsWith("//"))
    .map!(s => s.splitter.map!(to!string).array)
    .each!((string[] s) {
      switch (s[0]) {
      case "start:":
        root = s[1];
        break;
      case "accept:":
        accept = s[1];
        break;
      case "reject:":
        reject = s[1];
        break;
      case "blank:":
        blank = s[1][0];
        break;
      default:
        string curName = s[0];
        char curChar = s[1][0];
        string nextName = s[3];
        char nextChar = s[4][0];
        int delta = 0;

        switch (s[5]) {
        case ">":
          delta = 1;
          break;
        case "<":
          delta = -1;
          break;
        default:
          break;
        }
        Node cur = nodeByName.require(curName, new Node);
        nodeByName.require(nextName, new Node);
        cur.next[curChar] = Node.Next(delta, nextChar, nextName);
        break;
      }
    });
  auto line = new Line(args[2], blank);
  line.printState("", root);
  while (root != accept && root != reject) {
    auto nexts = nodeByName[root].next;

    if (line.get !in nexts) {
      line.printState(root, reject);
      break;
    }
    Node.Next next = nexts[line.get];
    line.put(next.ch);
    line.move(next.delta);
    line.printState(root, next.next);
    root = next.next;
  }
}
