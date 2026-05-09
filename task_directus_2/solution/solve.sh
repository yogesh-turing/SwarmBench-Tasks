#!/bin/bash
set -euo pipefail

cd /testbed

python3 - <<'PY'
from pathlib import Path
import json
import re
import sys


def read(path: Path) -> str:
        if not path.exists():
                print(f"missing file: {path}", file=sys.stderr)
                sys.exit(1)
        return path.read_text(encoding="utf-8")


def write(path: Path, text: str) -> None:
        path.write_text(text, encoding="utf-8")


def replace_once(text: str, old: str, new: str, label: str) -> str:
        if old not in text:
                print(f"anchor not found for {label}", file=sys.stderr)
                sys.exit(1)
        return text.replace(old, new, 1)


def ensure_use_shortcut() -> None:
        path = Path("packages/composables/src/use-shortcut.ts")
        text = read(path)

        if "function attachGlobalListeners()" not in text:
                text = replace_once(
                        text,
                        "const handlers: Record<string, ShortcutHandler[]> = {};\n\ndocument.body.addEventListener('keydown', (event: KeyboardEvent) => {\n\tif (event.repeat || !event.key) return;\n\n\tkeysDown.add(mapKeys(event));\n\tcallHandlers(event);\n});\n\ndocument.body.addEventListener('keyup', (event: KeyboardEvent) => {\n\tif (event.repeat || !event.key) return;\n\tkeysDown.clear();\n});\n",
                        "const handlers: Record<string, ShortcutHandler[]> = {};\nlet listenersAttached = false;\n\nfunction attachGlobalListeners() {\n\tif (listenersAttached) return;\n\tlistenersAttached = true;\n\n\tdocument.body.addEventListener('keydown', (event: KeyboardEvent) => {\n\t\tif (event.repeat || !event.key) return;\n\n\t\tkeysDown.add(mapKeys(event));\n\t\tcallHandlers(event);\n\t});\n\n\tdocument.body.addEventListener('keyup', (event: KeyboardEvent) => {\n\t\tif (event.repeat || !event.key) return;\n\t\tkeysDown.clear();\n\t});\n}\n",
                        "issue-27119-listener-block",
                )

        if "attachGlobalListeners();" not in text:
                text = replace_once(
                        text,
                        "\tonMounted(() => {\n\t\t[shortcuts].flat().forEach((shortcut) => {",
                        "\tonMounted(() => {\n\t\tattachGlobalListeners();\n\n\t\t[shortcuts].flat().forEach((shortcut) => {",
                        "issue-27119-onmounted-call",
                )

        required = [
                "function attachGlobalListeners()",
                "if (listenersAttached) return;",
                "listenersAttached = true;",
                "attachGlobalListeners();",
        ]
        for token in required:
                if token not in text:
                        print(f"missing token in use-shortcut.ts: {token}", file=sys.stderr)
                        sys.exit(1)

        write(path, text)


def ensure_ts_build_config() -> None:
        tsdown_path = Path("api/tsdown.config.ts")
        tsconfig_path = Path("api/tsconfig.prod.json")

        tsdown = read(tsdown_path)
        if "!src/test-utils" not in tsdown:
                tsdown = replace_once(
                        tsdown,
                        "entry: ['src/**/*.ts', '!src/**/*.d.ts', '!src/**/*.test.ts'],",
                        "entry: [\n\t\t'src/**/*.ts',\n\t\t'!src/**/*.d.ts',\n\t\t'!src/**/*.test.ts',\n\t\t'!src/__utils__',\n\t\t'!src/__setup__',\n\t\t'!src/test-utils',\n\t\t'!src/database/run-ast/lib/apply-query/mock.ts',\n\t],",
                        "issue-26978-tsdown-entry",
                )
        if "treeshake: false" in tsdown:
                tsdown = tsdown.replace("\n\ttreeshake: false,", "")

        for token in ["!src/test-utils", "!src/__utils__", "!src/__setup__", "!src/database/run-ast/lib/apply-query/mock.ts"]:
                if token not in tsdown:
                        print(f"missing exclusion in tsdown.config.ts: {token}", file=sys.stderr)
                        sys.exit(1)
        write(tsdown_path, tsdown)

        tsconfig = json.loads(read(tsconfig_path))
        excludes = tsconfig.get("exclude", [])
        if "src/test-utils" not in excludes:
                excludes.append("src/test-utils")
        tsconfig["exclude"] = excludes
        write(tsconfig_path, json.dumps(tsconfig, indent="\t") + "\n")


def ensure_collections_validation() -> None:
        path = Path("api/src/services/collections.ts")
        text = read(path)

        if "payload.collection.includes('/')" not in text and 'payload.collection.includes("/")' not in text:
                text = replace_once(
                        text,
                        "\t\tif (payload.collection.startsWith('directus_')) {\n\t\t\tthrow new InvalidPayloadError({ reason: `Collections can't start with \"directus_\"` });\n\t\t}\n\n\t\tpayload.collection = await this.helpers.schema.parseCollectionName(payload.collection);",
                        "\t\tif (payload.collection.startsWith('directus_')) {\n\t\t\tthrow new InvalidPayloadError({ reason: `Collections can't start with \"directus_\"` });\n\t\t}\n\n\t\tif (payload.collection.includes('/')) {\n\t\t\tthrow new InvalidPayloadError({ reason: `Collection name can't contain \"/\"` });\n\t\t}\n\n\t\tpayload.collection = await this.helpers.schema.parseCollectionName(payload.collection);",
                        "issue-27093-slash-validation",
                )

        if "InvalidPayloadError" not in text or "includes('/')" not in text and 'includes("/")' not in text:
                print("slash validation in collections.ts is incomplete", file=sys.stderr)
                sys.exit(1)
        write(path, text)


def ensure_versions_accountability() -> None:
        path = Path("api/src/services/versions.ts")
        text = read(path)

        if "trackingAccountability" not in text:
                block_pattern = re.compile(
                        r"\n\t\tconst activityService = new ActivityService\(\{.*?\n\t\tawait revisionsService\.createOne\(\{\n\t\t\tactivity,\n\t\t\tversion: key,\n\t\t\tcollection,\n\t\t\titem,\n\t\t\tdata: revisionDelta,\n\t\t\tdelta: revisionDelta,\n\t\t\}\);\n",
                        re.DOTALL,
                )
                replacement = "\n\t\tconst trackingAccountability = this.schema.collections[collection]?.accountability ?? null;\n\n\t\tif (trackingAccountability !== null) {\n\t\t\tconst activityService = new ActivityService({\n\t\t\t\tknex: this.knex,\n\t\t\t\tschema: this.schema,\n\t\t\t});\n\n\t\t\tconst activity = await activityService.createOne({\n\t\t\t\taction: Action.VERSION_SAVE,\n\t\t\t\tuser: this.accountability?.user ?? null,\n\t\t\t\tcollection,\n\t\t\t\tip: this.accountability?.ip ?? null,\n\t\t\t\tuser_agent: this.accountability?.userAgent ?? null,\n\t\t\t\torigin: this.accountability?.origin ?? null,\n\t\t\t\titem,\n\t\t\t});\n\n\t\t\tif (trackingAccountability === 'all') {\n\t\t\t\tconst revisionsService = new RevisionsService({\n\t\t\t\t\tknex: this.knex,\n\t\t\t\t\tschema: this.schema,\n\t\t\t\t});\n\n\t\t\t\tawait revisionsService.createOne({\n\t\t\t\t\tactivity,\n\t\t\t\t\tversion: key,\n\t\t\t\t\tcollection,\n\t\t\t\t\titem,\n\t\t\t\t\tdata: revisionDelta,\n\t\t\t\t\tdelta: revisionDelta,\n\t\t\t\t});\n\t\t\t}\n\t\t}\n"
                text, count = block_pattern.subn(replacement, text, count=1)
                if count != 1:
                        print("failed to apply accountability patch in versions.ts", file=sys.stderr)
                        sys.exit(1)

        required = [
                "const trackingAccountability = this.schema.collections[collection]?.accountability ?? null;",
                "if (trackingAccountability !== null)",
                "if (trackingAccountability === 'all')",
                "activityService.createOne",
                "revisionsService.createOne",
        ]
        for token in required:
                if token not in text:
                        print(f"missing token in versions.ts: {token}", file=sys.stderr)
                        sys.exit(1)

        write(path, text)


ensure_use_shortcut()
ensure_ts_build_config()
ensure_collections_validation()
ensure_versions_accountability()

print("All four Directus fixes applied.")
PY
