"""Сверка скриптов двух .rbxl по пути, классу и тексту: собранного `rojo build` из src/ и исходного плейса.
usage: python -I verify_build.py <built.rbxl> <place.rbxl>   (код выхода 1 при расхождении)"""
import importlib.util, os, sys

spec = importlib.util.spec_from_file_location("export_rbxl", os.path.join(os.path.dirname(os.path.abspath(__file__)), "export_rbxl.py"))
export_rbxl = importlib.util.module_from_spec(spec)
spec.loader.exec_module(export_rbxl)


def scripts(place):
    inst = export_rbxl.parse(open(place, "rb").read())

    def path(k):
        out = []
        while k in inst:
            out.append(inst[k]["Name"])
            k = inst[k]["Parent"]
        return ".".join(reversed(out))

    return {path(k): (i["ClassName"], i.get("Source", b"").replace(b"\r\n", b"\n"))
            for k, i in inst.items() if i["ClassName"] in export_rbxl.SCRIPT_CLASSES}


def main(built, place):
    a, b = scripts(built), scripts(place)
    missing, extra = sorted(set(b) - set(a)), sorted(set(a) - set(b))
    differ = sorted(k for k in a if k in b and a[k] != b[k])
    print(f"в сборке: {len(a)}, в плейсе: {len(b)}")
    for title, items in (("нет в сборке", missing), ("лишние", extra), ("класс или текст расходятся", differ)):
        for k in items:
            print(f"{title}: {k}")
    sys.exit(1 if missing or extra or differ else 0)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
