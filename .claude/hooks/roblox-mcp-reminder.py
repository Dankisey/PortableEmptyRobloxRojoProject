"""Подаёт памятку по граблям инструмента Roblox Studio MCP ровно в момент его вызова.

PreToolUse-хук: на stdin приходит JSON вызова, на stdout — готовый ответ хука либо ничего.
Код живёт в Studio, файлов на диске нет, поэтому `paths` правил не срабатывает, и единственный
работающий триггер — сам инструмент. Памятки — в roblox-mcp-reminders.json рядом:
ключ — имя инструмента, значение — список строк. Правишь памятку — правь JSON.

Ответ печатается ASCII-escape'ами: stdout питона на Windows кодируется в системную кодировку,
и кириллица иначе превращается в мусор. Любая неожиданность — молчаливый выход с кодом 0:
сломавшийся хук ломает каждый вызов инструмента.
"""

import json
import os
import sys

REMINDERS_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "roblox-mcp-reminders.json")


def main():
    try:
        payload = json.load(sys.stdin)
        tool_name = payload.get("tool_name") or ""

        with open(REMINDERS_PATH, "rb") as file:
            reminders = json.loads(file.read().decode("utf-8"))
    except Exception:
        return

    lines = reminders.get(tool_name)

    if not lines:
        return

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": "\n".join(lines),
        }
    }))


if __name__ == "__main__":
    main()
