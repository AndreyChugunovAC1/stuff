import std;

void main(string[] args) {
  auto rnd = Random(unpredictableSeed);
  string[] lines;
  char[] letterSet = chain(iota!char('a', cast(char)('z' + 1)), iota!char('A', cast(char)('Z' + 1))).array;
  stdout.reopen(args[2], "w");

  string randString() {
    return generate!(() => letterSet[uniform!"[)"(0, letterSet.length, rnd)])
      .take(uniform!"[]"(10, 100, rnd))
      .array
      .to!string;
  }

  lines = File(args[1], "r").byLine
    .filter!(line => !line.strip.empty)
    .map!idup
    .array;

  string[] header = lines[0..4];
  string[] codeLines = lines[4..$];
  string[string] tokenMap;

  auto codeLinesSplitted = codeLines
    .map!(s => s.strip.split.array)
    .array;

  void addToken(string tok) {
    if (tok !in tokenMap) {
      tokenMap[tok] = randString;
    }
  }

  codeLinesSplitted.each!((sl) {
    addToken(sl[0]);
    addToken(sl[3]);
  });

  codeLinesSplitted.each!((sl) {
    sl[0] = tokenMap[sl[0]];
    sl[3] = tokenMap[sl[3]];
  });

  codeLinesSplitted = randomShuffle(codeLinesSplitted, rnd);
  foreach (ref line; header) {
    auto parts = line.split;
    if (parts[0] == "blank:") {
      continue;
    } else {
      if (parts[1] in tokenMap) {
        parts[1] = tokenMap[parts[1]];
      } else {
        parts[1] = randString;
      }
    }
    line = parts[0] ~ " " ~ parts[1];
  }
  header.each!writeln;
  codeLinesSplitted.map!(sl => sl.join(" ")).each!writeln;
}