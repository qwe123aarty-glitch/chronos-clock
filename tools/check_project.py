#!/usr/bin/env python3
"""Parse project.pbxproj as an OpenStep plist and sanity-check its graph."""
import re, sys, os, json

PATH = sys.argv[1] if len(sys.argv) > 1 else r"D:/Newthings/chronos-clock/Chronos.xcodeproj/project.pbxproj"
ROOT = os.path.dirname(os.path.dirname(PATH))

src = open(PATH, encoding="utf-8").read()

# ---- tokenizer ----------------------------------------------------------
TOKEN_RE = re.compile(r'''
    (?P<comment>/\*.*?\*/)
  | (?P<linecomment>//[^\n]*)
  | (?P<punct>[{}()=;,])
  | (?P<qstring>"(?:[^"\\]|\\.)*")
  | (?P<string>[^\s{}()=;,"]+)
''', re.S | re.X)


class Tok:
    def __init__(self, kind, val, pos):
        self.kind, self.val, self.pos = kind, val, pos

    def __repr__(self):
        return f"{self.kind}:{self.val!r}"


tokens = []
for m in TOKEN_RE.finditer(src):
    k = m.lastgroup
    if k in ("comment", "linecomment"):
        continue
    v = m.group()
    if k == "qstring":
        v = v[1:-1]
    tokens.append(Tok(k, v, m.start()))

# catch characters the tokenizer skipped
covered = set()
for m in TOKEN_RE.finditer(src):
    covered.update(range(m.start(), m.end()))
for i, ch in enumerate(src):
    if i not in covered and not ch.isspace():
        print(f"FAIL: stray character {ch!r} at offset {i}")
        sys.exit(1)


class Parser:
    def __init__(self, toks):
        self.t = toks
        self.i = 0

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else None

    def next(self):
        tok = self.t[self.i]
        self.i += 1
        return tok

    def expect(self, val):
        tok = self.next()
        if tok.val != val:
            raise SyntaxError(f"expected {val!r} at offset {tok.pos}, got {tok.val!r}")

    def value(self):
        tok = self.peek()
        if tok is None:
            raise SyntaxError("unexpected EOF")
        if tok.val == "{":
            return self.dictionary()
        if tok.val == "(":
            return self.array()
        self.next()
        return tok.val

    def dictionary(self):
        self.expect("{")
        d = {}
        while True:
            tok = self.peek()
            if tok is None:
                raise SyntaxError("unterminated dictionary")
            if tok.val == "}":
                self.next()
                return d
            key = self.next().val
            self.expect("=")
            d[key] = self.value()
            self.expect(";")

    def array(self):
        self.expect("(")
        a = []
        while True:
            tok = self.peek()
            if tok is None:
                raise SyntaxError("unterminated array")
            if tok.val == ")":
                self.next()
                return a
            a.append(self.value())
            tok = self.peek()
            if tok is not None and tok.val == ",":
                self.next()


try:
    tree = Parser(tokens).value()
except SyntaxError as e:
    print(f"FAIL: {e}")
    sys.exit(1)

print("OK   syntax parses as OpenStep plist")

# ---- graph checks -------------------------------------------------------
objects = tree.get("objects", {})
UUID = re.compile(r"^[0-9A-F]{24}$")

bad_len = [k for k in objects if not UUID.match(k)]
if bad_len:
    print(f"FAIL: object keys that are not 24-char hex: {bad_len}")
    sys.exit(1)
print(f"OK   {len(objects)} objects, all keys are 24-char uppercase hex")

refs = set()


def walk(node):
    if isinstance(node, dict):
        for v in node.values():
            walk(v)
    elif isinstance(node, list):
        for v in node:
            walk(v)
    elif isinstance(node, str) and UUID.match(node):
        refs.add(node)


for k, v in objects.items():
    walk(v)
walk(tree.get("rootObject"))

missing = sorted(refs - set(objects))
if missing:
    print(f"FAIL: {len(missing)} dangling UUID references: {missing}")
    sys.exit(1)
print(f"OK   {len(refs)} UUID references, none dangling")

orphans = sorted(set(objects) - refs - {tree.get("rootObject")})
if orphans:
    print(f"WARN unreferenced objects: {orphans}")

# every PBXBuildFile must point at a PBXFileReference
for uid, obj in objects.items():
    if obj.get("isa") == "PBXBuildFile":
        fr = obj.get("fileRef")
        if fr not in objects or objects[fr].get("isa") != "PBXFileReference":
            print(f"FAIL: PBXBuildFile {uid} has invalid fileRef {fr}")
            sys.exit(1)
print("OK   every PBXBuildFile resolves to a PBXFileReference")

# every file reference on disk
missing_files = []
for uid, obj in objects.items():
    if obj.get("isa") == "PBXFileReference":
        p = obj.get("path")
        if p and obj.get("sourceTree") == "<group>":
            if not os.path.exists(os.path.join(ROOT, "Chronos", p)):
                missing_files.append(p)
if missing_files:
    print(f"FAIL: file references missing on disk: {missing_files}")
    sys.exit(1)
print("OK   every source file reference exists on disk")

# build phase sanity
target = next(o for o in objects.values() if o.get("isa") == "PBXNativeTarget")
phases = target["buildPhases"]
srcs = next(objects[p] for p in phases if objects[p]["isa"] == "PBXSourcesBuildPhase")
res = next(objects[p] for p in phases if objects[p]["isa"] == "PBXResourcesBuildPhase")
print(f"OK   target '{target['name']}' -> {len(srcs['files'])} sources, {len(res['files'])} resources")

swift_on_disk = [f for f in os.listdir(os.path.join(ROOT, "Chronos")) if f.endswith(".swift")]
if len(swift_on_disk) != len(srcs["files"]):
    print(f"FAIL: {len(swift_on_disk)} .swift files on disk vs {len(srcs['files'])} in Sources phase")
    sys.exit(1)
print(f"OK   all {len(swift_on_disk)} swift files are in the Sources phase")

# scheme blueprint must match the target UUID
scheme = os.path.join(ROOT, "Chronos.xcodeproj", "xcshareddata", "xcschemes", "Chronos.xcscheme")
if os.path.exists(scheme):
    s = open(scheme, encoding="utf-8").read()
    target_id = next(k for k, o in objects.items() if o.get("isa") == "PBXNativeTarget")
    if target_id not in s:
        print(f"FAIL: scheme does not reference target {target_id}")
        sys.exit(1)
    print("OK   scheme BlueprintIdentifier matches the native target")
else:
    print("WARN no shared scheme found")

print("\nALL CHECKS PASSED")
