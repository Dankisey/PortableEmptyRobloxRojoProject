"""Delivers the pitfall reminder of a Roblox Studio MCP tool at the moment the tool is called.

A PreToolUse hook: the call JSON arrives on stdin, a ready hook answer or nothing goes to stdout.
Code lives in Studio, so rule `paths` never fire and the tool itself is the only working trigger.
Reminders live in roblox-mcp-reminders.json next to this file: key is the tool name, value is a list of lines.

Any surprise ends with a silent exit code 0: a broken hook breaks every tool call.
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
