#!/usr/bin/env python3
"""Render the version table in README.md from versions.json.

Run locally (`python scripts/render_versions.py`) or from CI — it rewrites the
block between the VERSIONS markers in README.md and is a no-op if nothing changed.
Each row carries two ways to install: the unsigned IPA from the matching GitHub
Release, and the AltStore source that installs and updates it automatically.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA = json.loads((ROOT / "versions.json").read_text(encoding="utf-8"))
README = ROOT / "README.md"

START = "<!-- VERSIONS:TABLE:START -->"
END = "<!-- VERSIONS:TABLE:END -->"

REPO = DATA["repo"]
ASSET = DATA["release_asset"]
FEED = DATA.get("altstore_feed")


def badge(label, color, logo):
    label = label.replace("-", "--").replace(" ", "%20")
    return f"https://img.shields.io/badge/{label}-{color}?style=flat-square&logo={logo}&logoColor=white"


def download_cell(entry):
    buttons = []
    tag = entry.get("release_tag")
    if tag:
        # CI tags releases v1.0.N, so "latest" means GitHub's newest-release redirect.
        path = "latest/download" if tag == "latest" else f"download/{tag}"
        url = f"https://github.com/{REPO}/releases/{path}/{ASSET}"
        buttons.append(
            f'<a href="{url}"><img src="{badge("IPA download", "2EA44F", "apple")}" alt="Download {ASSET}"></a>'
        )
    ipa = entry.get("ipa")
    if ipa:
        url = f"https://github.com/{REPO}/raw/main/IPAs/{ipa}"
        buttons.append(
            f'<a href="{url}"><img src="{badge("IPA in-repo", "24292E", "github")}" alt="Download {ipa} from repo"></a>'
        )
    if FEED:
        buttons.append(
            f'<a href="{FEED}"><img src="{badge("AltStore source", "0B84FF", "altstore")}" alt="AltStore source feed"></a>'
        )
    return "<br>".join(buttons)


def render():
    rows = []
    for i, entry in enumerate(DATA["versions"], start=1):
        changes = "".join(f"<li>{c}</li>" for c in entry["changes"])
        rows.append(
            "<tr>"
            f'<td align="center">{i}</td>'
            f'<td align="center"><strong>v{entry["version"]}</strong><br><sub>{entry["date"]}</sub></td>'
            f"<td><ul>{changes}</ul></td>"
            f'<td align="center">{download_cell(entry)}</td>'
            "</tr>"
        )
    return (
        "<table>\n"
        "<thead><tr>"
        "<th>#</th><th>Version</th><th>Changes &amp; features</th><th>Install</th>"
        "</tr></thead>\n"
        "<tbody>\n" + "\n".join(rows) + "\n</tbody>\n</table>"
    )


def main():
    text = README.read_text(encoding="utf-8")
    if START not in text or END not in text:
        sys.exit(f"README.md is missing the {START} / {END} markers.")
    block = f"{START}\n{render()}\n{END}"
    new = re.sub(re.escape(START) + r".*?" + re.escape(END), block, text, flags=re.DOTALL)
    if new != text:
        README.write_text(new, encoding="utf-8")
        print("README version table updated.")
    else:
        print("README version table already current.")


if __name__ == "__main__":
    main()
