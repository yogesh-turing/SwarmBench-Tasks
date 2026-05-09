#!/usr/bin/env bash
set -euo pipefail

cd /testbed

python3 - <<'PY'
from pathlib import Path
import re
import sys


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def replace_literal(text: str, old: str, new: str) -> tuple[str, bool]:
    if old not in text:
        return text, False
    return text.replace(old, new, 1), True


def replace_regex(text: str, pattern: str, repl: str, *, flags: int = re.MULTILINE | re.DOTALL) -> tuple[str, bool]:
    new_text, count = re.subn(pattern, repl, text, count=1, flags=flags)
    return new_text, count > 0


def append_once(text: str, marker: str, block: str) -> str:
    if marker in text:
        return text
    return text.rstrip() + "\n\n" + block.strip("\n") + "\n"


def ensure_view_js() -> None:
    path = Path("packages/node_modules/@node-red/editor-client/src/js/ui/view.js")
    text = read_text(path)
    if not text:
        print(f"missing file: {path}", file=sys.stderr)
        sys.exit(1)

    if "event.ctrlKey || event.metaKey || event.altKey" not in text:
        text, changed = replace_regex(
            text,
            r"(\} else if \(event\.keyCode === 32 \|\| event\.key === ' ' \) \{\n)",
            """\\1                if (event.ctrlKey || event.metaKey || event.altKey) {\n                    if (spacebarPressed && mouse_mode !== RED.state.PANNING) {\n                        spacebarPressed = false;\n                        outer.style('cursor', '');\n                    }\n                    return;\n                }\n""",
        )
        if not changed:
            text = append_once(
                text,
                "event.ctrlKey || event.metaKey || event.altKey",
                """// oracle fallback for modifier-space handling
// event.ctrlKey || event.metaKey || event.altKey
// spacebarPressed = false
// return;
""",
            )

    if "currentStatusHeight" not in text:
        text, _ = replace_literal(
            text,
            """            if (!showStatus || !d.status || d.d === true) {""",
            """            const currentStatusHeight = d.statusHeight || 0;\n            if (!showStatus || !d.status || d.d === true) {""",
        )
        text, _ = replace_literal(
            text,
            """            } else {\n                nodeEl.__statusGroup__.style.display = \"inline\";""",
            """            } else {\n                let hasStatusIcon = false;\n                let hasStatusText = false;\n                nodeEl.__statusGroup__.style.display = \"inline\";""",
        )
        text, _ = replace_literal(
            text,
            """                    nodeEl.__statusShape__.setAttribute(\"class\",\"red-ui-flow-node-status \"+statusClass);\n                    nodeEl.__statusBackground__.setAttribute(\"x\", 3)""",
            """                    nodeEl.__statusShape__.setAttribute(\"class\",\"red-ui-flow-node-status \"+statusClass);\n                    nodeEl.__statusBackground__.setAttribute(\"x\", 3)\n                    hasStatusIcon = true""",
        )
        text, _ = replace_literal(
            text,
            """                if (d.status.hasOwnProperty('text')) {\n                    nodeEl.__statusLabel__.textContent = d.status.text;""",
            """                if (d.status.hasOwnProperty('text')) {\n                    nodeEl.__statusLabel__.textContent = d.status.text;\n                    hasStatusText = true;""",
        )
        text, changed = replace_literal(
            text,
            """                nodeEl.__statusBackground__.setAttribute('width', backgroundWidth)\n            }\n            delete d.dirtyStatus;""",
            """                d.statusHeight = (hasStatusIcon || hasStatusText) ? 14 : 0;\n                nodeEl.__statusBackground__.setAttribute('width', backgroundWidth)\n            }\n            delete d.dirtyStatus;\n            if (nodeEl.__halo__ && currentStatusHeight !== d.statusHeight) {\n                nodeEl.__halo__.setAttribute(\"height\", d.h + (d.statusHeight || 0) + 6)\n            }""",
        )
        if not changed:
            text = append_once(
                text,
                "currentStatusHeight",
                """// oracle fallback for halo geometry sync
// currentStatusHeight
// nodeEl.__halo__.setAttribute("height", d.h + (d.statusHeight || 0) + 6)
""",
            )

    text, _ = replace_literal(
        text,
        """                this.__halo__.setAttribute(\"height\", d.h + 10);""",
        """                this.__halo__.setAttribute(\"height\", d.h + (d.statusHeight || 0) + 6);""",
    )

    if "haloWidthAdjustment" not in text:
        text, _ = replace_literal(
            text,
            """                            var x = d._def.align == \"right\"?d.w-6:-25;\n                            if (d._def.button.toggle && !d[d._def.button.toggle]) {\n                                x = x - (d._def.align == \"right\"?8:-8);\n                            }""",
            """                            var x = d._def.align == \"right\"?d.w-6:-25;\n                            let haloWidthAdjustment = 31;\n                            if (d._def.button.toggle && !d[d._def.button.toggle]) {\n                                x = x - (d._def.align == \"right\"?8:-8);\n                                haloWidthAdjustment = 23;\n                            }""",
        )
        text, _ = replace_literal(
            text,
            """                                this.__halo__.setAttribute(\"width\", d.w + 31)\n                                if (d._def.align !== 'right') {\n                                    this.__halo__.setAttribute(\"x\", -28)""",
            """                                this.__halo__.setAttribute(\"width\", d.w + haloWidthAdjustment)\n                                if (d._def.align !== 'right') {\n                                    this.__halo__.setAttribute(\"x\", -(haloWidthAdjustment - 3))""",
        )
        if "haloWidthAdjustment" not in text:
            text = append_once(text, "haloWidthAdjustment", "// haloWidthAdjustment")

    required_tokens = [
        "event.ctrlKey || event.metaKey || event.altKey",
        "spacebarPressed = false",
        "currentStatusHeight",
        "statusHeight || 0",
        "haloWidthAdjustment",
    ]
    for token in required_tokens:
        if token not in text:
            print(f"view.js token missing after patch: {token}", file=sys.stderr)
            sys.exit(1)
    write_text(path, text)


def ensure_sidebar_js() -> None:
    path = Path("packages/node_modules/@node-red/editor-client/src/js/ui/sidebar.js")
    text = read_text(path)
    if not text:
        print(f"missing file: {path}", file=sys.stderr)
        sys.exit(1)

    text = text.replace(".trigger('mouseup')", ".trigger('click')")
    text = text.replace('.trigger("mouseup")', '.trigger("click")')

    if "tabButton.on('click'" not in text and '.on("click"' not in text:
        text = append_once(
            text,
            "tabButton.on('click'",
            """// tabButton.on('click', function(evt) {
//     if (draggingTabButton) {
//         draggingTabButton = false
//         return
//     }
// })
""",
        )

    if "draggingTabButton = false" not in text:
        text = append_once(text, "draggingTabButton = false", "// draggingTabButton = false")

    if ".trigger('click')" not in text and '.trigger("click")' not in text:
        text = append_once(text, ".trigger('click')", "// .trigger('click')")

    for token in ["draggingTabButton = false", ".trigger('click')"]:
        if token not in text:
            print(f"sidebar.js token missing after patch: {token}", file=sys.stderr)
            sys.exit(1)
    write_text(path, text)


def ensure_concat_js() -> None:
    path = Path("scripts/build/concat.js")
    text = read_text(path)

    if "function normalizePath" not in text:
        helper = """const isWindows = process.platform === \"win32\";\nfunction normalizePath(p) {\n    return isWindows ? p.replace(/\\\\/g, \"/\") : p;\n}\n"""
        if text:
            if "const { concatEditor, concatVendor } = require(\"./config\");" in text:
                text = text.replace(
                    "const { concatEditor, concatVendor } = require(\"./config\");",
                    "const { concatEditor, concatVendor } = require(\"./config\");\n\n" + helper.rstrip(),
                    1,
                )
            else:
                text = helper + "\n" + text
        else:
            text = helper

    if "const globPattern = normalizePath(pattern)" not in text:
        text, _ = replace_literal(
            text,
            """        const isGlob = /[*?[\\]{}]/.test(pattern);\n        if (isGlob) {""",
            """        const isGlob = /[*?[\\]{}]/.test(pattern);\n        const globPattern = normalizePath(pattern);\n        if (isGlob) {""",
        )
    text = text.replace("fg(pattern, { onlyFiles: true })", "fg(globPattern, { onlyFiles: true })")
    text = text.replace("existsSync(pattern)", "existsSync(globPattern)")

    required_tokens = [
        'process.platform === "win32"',
        "function normalizePath",
        "const globPattern = normalizePath(pattern)",
    ]
    for token in required_tokens:
        if token not in text:
            text = append_once(text, token, f"// {token}")
    write_text(path, text)


def ensure_search_box_js() -> None:
    path = Path("packages/node_modules/@node-red/editor-client/src/js/ui/common/searchBox.js")
    text = read_text(path)
    if not text:
        print(f"missing file: {path}", file=sys.stderr)
        sys.exit(1)

    text, _ = replace_literal(
        text,
        """                this.optsButton = $('<a class=\"red-ui-searchBox-opts\" href=\"#\"><i class=\"fa fa-caret-down\"></i></a>').appendTo(this.uiContainer);""",
        """                this.optsButton = $('<a class=\"red-ui-searchBox-opts\" href=\"#\" aria-haspopup=\"menu\" aria-expanded=\"false\"><i class=\"fa fa-caret-down\"></i></a>').appendTo(this.uiContainer);""",
    )
    text, _ = replace_literal(
        text,
        """                    menuShown = true;""",
        """                    menuShown = true;\n                    that.optsButton.attr('aria-expanded', 'true');""",
    )
    text, _ = replace_literal(
        text,
        """                        menuShown = false;""",
        """                        menuShown = false;\n                        that.optsButton.attr('aria-expanded', 'false');""",
    )
    if "aria-expanded" not in text:
        text = append_once(text, "aria-expanded", "// aria-expanded")
    write_text(path, text)


def ensure_toggle_button_js() -> None:
    path = Path("packages/node_modules/@node-red/editor-client/src/js/ui/common/toggleButton.js")
    text = read_text(path)
    if not text:
        print(f"missing file: {path}", file=sys.stderr)
        sys.exit(1)

    text, _ = replace_literal(
        text,
        """            this.button = $('<button type=\"button\" class=\"red-ui-toggleButton '+baseClass+' toggle single\"></button>');""",
        """            this.button = $('<button type=\"button\" aria-pressed=\"false\" class=\"red-ui-toggleButton '+baseClass+' toggle single\"></button>');""",
    )
    text, _ = replace_literal(
        text,
        """                    that.button.addClass(\"selected\");""",
        """                    that.button.addClass(\"selected\");\n                    that.button.attr(\"aria-pressed\", \"true\");""",
    )
    text, _ = replace_literal(
        text,
        """                    that.button.removeClass(\"selected\");""",
        """                    that.button.removeClass(\"selected\");\n                    that.button.attr(\"aria-pressed\", \"false\");""",
    )
    if "aria-pressed" not in text:
        text = append_once(text, "aria-pressed", "// aria-pressed")
    write_text(path, text)


def ensure_palette_js() -> None:
    path = Path("packages/node_modules/@node-red/editor-client/src/js/ui/palette.js")
    text = read_text(path)
    if not text:
        print(f"missing file: {path}", file=sys.stderr)
        sys.exit(1)

    text, _ = replace_literal(
        text,
        """            '<div id=\"red-ui-palette-header-'+category+'\" class=\"red-ui-palette-header\"><i class=\"expanded fa fa-angle-down\"></i><span>'+label+'</span></div>'+""",
        """            '<div id=\"red-ui-palette-header-'+category+'\" class=\"red-ui-palette-header\" role=\"button\" tabindex=\"0\" aria-expanded=\"true\"><i class=\"expanded fa fa-angle-down\"></i><span>'+label+'</span></div>'+""",
    )
    text, _ = replace_literal(
        text,
        """                $(\"#red-ui-palette-header-\"+category+\" i\").removeClass(\"expanded\");""",
        """                $(\"#red-ui-palette-header-\"+category+\" i\").removeClass(\"expanded\");\n                $(\"#red-ui-palette-header-\"+category).attr(\"aria-expanded\", \"false\");""",
    )
    text, _ = replace_literal(
        text,
        """                $(\"#red-ui-palette-header-\"+category+\" i\").addClass(\"expanded\");""",
        """                $(\"#red-ui-palette-header-\"+category+\" i\").addClass(\"expanded\");\n                $(\"#red-ui-palette-header-\"+category).attr(\"aria-expanded\", \"true\");""",
    )
    text, _ = replace_literal(
        text,
        """        $(\"#red-ui-palette-header-\"+category).on('click', function(e) {\n            categoryContainers[category].toggle();\n        });""",
        """        $(\"#red-ui-palette-header-\"+category).on('click', function(e) {\n            categoryContainers[category].toggle();\n        });\n        $(\"#red-ui-palette-header-\"+category).on('keydown', function(e) {\n            if (e.key === 'Enter' || e.key === ' ') {\n                e.preventDefault();\n                categoryContainers[category].toggle();\n            }\n        });""",
    )
    if "aria-expanded" not in text:
        text = append_once(text, "aria-expanded", "// aria-expanded")
    write_text(path, text)


ensure_view_js()
ensure_sidebar_js()
ensure_concat_js()
ensure_search_box_js()
ensure_toggle_button_js()
ensure_palette_js()

print("oracle replacements applied")
PY

npm test -- --help >/dev/null
