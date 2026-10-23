"""Delivers the animation and UI principles reminder when an MCP edit touches animation or interface code.

A PreToolUse hook: the call JSON arrives on stdin, a ready hook answer or nothing goes to stdout.
Groups and their keywords live in principles-reminders.json next to this file; a group fires when any
of its keywords appears as a whole word in any string of the tool input.

Any surprise ends with a silent exit code 0: a broken hook breaks every tool call.
"""

import json
import os
import re
import sys

REMINDERS_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "principles-reminders.json")


def strings_of(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from strings_of(item)
    elif isinstance(value, list):
        for item in value:
            yield from strings_of(item)


def main():
    try:
        payload = json.load(sys.stdin)

        with open(REMINDERS_PATH, "rb") as file:
            groups = json.loads(file.read().decode("utf-8"))
    except Exception:
        return

    text = "\n".join(strings_of(payload.get("tool_input", {})))
    lines = []

    for group in groups.values():
        keywords = group.get("keywords", [])
        pattern = r"(?<![\w])(" + "|".join(re.escape(word) for word in keywords) + r")(?![\w])"

        if keywords and re.search(pattern, text):
            lines.extend(group.get("lines", []))

    if not lines:
        return

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": "\n".join(lines),
        }
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
