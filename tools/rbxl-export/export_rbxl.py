"""Выгрузка скриптов и папок из сохранённого .rbxl в раскладку Rojo; GUI, ремоуты и ассеты не выгружаются.
usage: python -I export_rbxl.py <place.rbxl> <out_src_dir>   (out_src_dir пустой или не существует; Python 3.14+)"""
import json, os, struct, sys
from compression import zstd

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
ROOTS = {
    ("ReplicatedFirst",): "ReplicatedFirst",
    ("ReplicatedStorage",): "ReplicatedStorage",
    ("ServerScriptService",): "ServerScriptService",
    ("ServerStorage",): "ServerStorage",
    ("StarterGui",): "StarterGui",
    ("StarterPlayer", "StarterCharacterScripts"): "StarterPlayer/StarterCharacterScripts",
    ("StarterPlayer", "StarterPlayerScripts"): "StarterPlayer/StarterPlayerScripts",
    ("Workspace",): "Workspace",
}
BAD_CHARS = set('<>:"/\\|?*')


def lz4_block(src, size):
    out, p = bytearray(), 0
    while p < len(src):
        tok = src[p]; p += 1
        n = tok >> 4
        if n == 15:
            while True:
                b = src[p]; p += 1; n += b
                if b != 255:
                    break
        out += src[p:p + n]; p += n
        if p >= len(src):
            break
        off = src[p] | (src[p + 1] << 8); p += 2
        m = tok & 15
        if m == 15:
            while True:
                b = src[p]; p += 1; m += b
                if b != 255:
                    break
        m += 4
        for _ in range(m):
            out.append(out[-off])
    assert len(out) == size
    return bytes(out)


def read_chunks(data):
    assert data[:8] == b"<roblox!"
    p = 32
    while p < len(data):
        name = data[p:p + 4]
        comp, unc = struct.unpack("<II", data[p + 4:p + 12])
        raw = data[p + 16:p + 16 + (comp or unc)]
        p += 16 + (comp or unc)
        if comp:
            raw = zstd.decompress(raw) if raw[:4] == b"\x28\xb5\x2f\xfd" else lz4_block(raw, unc)
        yield name.rstrip(b"\0").decode(), raw
        if name == b"END\0":
            break


class R:
    def __init__(self, b):
        self.b, self.p = b, 0

    def u8(self):
        self.p += 1
        return self.b[self.p - 1]

    def u32(self):
        self.p += 4
        return struct.unpack_from("<I", self.b, self.p - 4)[0]

    def bstr(self):
        n = self.u32()
        self.p += n
        return self.b[self.p - n:self.p]

    def interleaved(self, n):
        raw = self.b[self.p:self.p + 4 * n]
        self.p += 4 * n
        return [(raw[i] << 24) | (raw[n + i] << 16) | (raw[2 * n + i] << 8) | raw[3 * n + i] for i in range(n)]

    def refs(self, n):
        out, acc = [], 0
        for x in self.interleaved(n):
            acc += (x >> 1) ^ -(x & 1)
            out.append(acc)
        return out


def parse(data):
    classes, inst, shared = {}, {}, []
    for name, b in read_chunks(data):
        r = R(b)
        if name == "INST":
            cid = r.u32(); cname = r.bstr().decode(); r.u8(); n = r.u32()
            ids = r.refs(n)
            classes[cid] = (cname, ids)
            for i in ids:
                inst[i] = {"ClassName": cname, "Parent": -1}
        elif name == "SSTR":
            r.u32(); n = r.u32()
            for _ in range(n):
                r.p += 16
                shared.append(r.bstr())
        elif name == "PROP":
            cid = r.u32(); prop = r.bstr().decode(); t = r.u8()
            cname, ids = classes[cid]
            if prop not in ("Name", "Source", "Disabled", "RunContext"):
                continue
            n = len(ids)
            if t == 0x01:
                vals = [r.bstr() for _ in range(n)]
            elif t == 0x1C:
                vals = [shared[i] for i in r.interleaved(n)]
            elif t == 0x02:
                vals = [bool(r.u8()) for _ in range(n)]
            elif t == 0x12:
                vals = r.interleaved(n)
            else:
                sys.exit(f"{cname}.{prop}: неожиданный тип 0x{t:02x}")
            for i, v in zip(ids, vals):
                inst[i][prop] = v
        elif name == "PRNT":
            r.u8(); n = r.u32()
            for c, par in zip(r.refs(n), r.refs(n)):
                inst[c]["Parent"] = par
    for i in inst.values():
        i["Name"] = i.get("Name", b"").decode("utf-8")
        i["Children"] = []
    for k, i in inst.items():
        if i["Parent"] in inst:
            inst[i["Parent"]]["Children"].append(k)
    return inst


def has_script(inst, k):
    i = inst[k]
    return i["ClassName"] in SCRIPT_CLASSES or any(has_script(inst, c) for c in i["Children"])


def write_meta(path, meta):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(meta, indent=4, ensure_ascii=False) + "\n")


def script_suffix(i, warnings, where):
    c = i["ClassName"]
    if c == "ModuleScript":
        return ".lua"
    if c == "LocalScript":
        return ".client.lua"
    if i.get("RunContext", 0) == 2:
        return ".client.lua"
    if i.get("RunContext", 0) not in (0, 1):
        warnings.append(f"{where}: RunContext={i['RunContext']}")
    return ".server.lua"


def emit(inst, k, out_dir, where, report):
    i = inst[k]
    name = i["Name"]
    if set(name) & BAD_CHARS or name in ("", ".", "..") or name.lower() == "init":
        report["warnings"].append(f"{where}: имя не годится для файла")
        return
    is_script = i["ClassName"] in SCRIPT_CLASSES
    kids = [c for c in i["Children"] if has_script(inst, c)]
    meta = {}
    if is_script and i.get("Disabled"):
        meta["properties"] = {"Disabled": True}
    if is_script and not kids:
        path = os.path.join(out_dir, name + script_suffix(i, report["warnings"], where))
        target_meta = os.path.join(out_dir, name + ".meta.json")
    else:
        d = os.path.join(out_dir, name)
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, "init" + script_suffix(i, report["warnings"], where)) if is_script else None
        if not is_script and i["ClassName"] != "Folder":
            meta["className"] = i["ClassName"]
        meta["ignoreUnknownInstances"] = True
        target_meta = os.path.join(d, "init.meta.json")
    if os.path.exists(path or target_meta) and path:
        report["warnings"].append(f"{where}: дубль имени, перезапись")
    if path:
        src = i.get("Source", b"")
        with open(path, "wb") as f:
            f.write(src)
        report["scripts"].append((where, path, src))
    if meta:
        write_meta(target_meta, meta)
    if not is_script or kids:
        seen = set()
        for c in kids:
            n = inst[c]["Name"]
            if n in seen:
                report["warnings"].append(f"{where}.{n}: одинаковые имена соседей")
            seen.add(n)
            emit(inst, c, os.path.join(out_dir, name), f"{where}.{n}", report)


def main(place, out):
    if os.path.isdir(out) and os.listdir(out):
        sys.exit(f"{out} не пуст: старые файлы остались бы в зеркале, удали папку перед выгрузкой")
    inst = parse(open(place, "rb").read())
    by_name = lambda parent, n: next((k for k, i in inst.items() if i["Parent"] == parent and i["Name"] == n), None)
    report = {"scripts": [], "warnings": []}
    covered = set()
    for chain, rel in ROOTS.items():
        k = -1
        for n in chain:
            k = by_name(k, n)
            if k is None:
                break
        if k is None:
            continue
        covered.add(k)
        d = os.path.join(out, rel)
        os.makedirs(d, exist_ok=True)
        write_meta(os.path.join(d, "init.meta.json"), {"ignoreUnknownInstances": True})
        for c in inst[k]["Children"]:
            if has_script(inst, c) and not (chain == ("StarterPlayer",)):
                emit(inst, c, d, ".".join(chain) + "." + inst[c]["Name"], report)
    sp = by_name(-1, "StarterPlayer")
    for k, i in inst.items():
        if i["Parent"] == -1 and k not in covered and has_script(inst, k) and k != sp:
            report["warnings"].append(f"скрипты вне проекта Rojo: {i['Name']}")
    if sp is not None:
        for c in inst[sp]["Children"]:
            if inst[c]["Name"] not in ("StarterCharacterScripts", "StarterPlayerScripts") and has_script(inst, c):
                report["warnings"].append(f"скрипты вне проекта Rojo: StarterPlayer.{inst[c]['Name']}")
    total = sum(1 for i in inst.values() if i["ClassName"] in SCRIPT_CLASSES)
    print(f"скриптов в плейсе: {total}, выгружено: {len(report['scripts'])}")
    for w in report["warnings"]:
        print("WARN", w)
    bad = 0
    for where, path, src in report["scripts"]:
        if open(path, "rb").read() != src:
            bad += 1
            print("MISMATCH", where)
        try:
            src.decode("utf-8")
        except UnicodeDecodeError:
            print("NOT UTF-8", where)
    print(f"сверка байт: расхождений {bad}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
