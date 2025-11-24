#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------
# Argument parsing
# ------------------------------------------
DRY_RUN=0
ROOT="."

if [[ "${1:-}" != "" ]]; then
  ROOT="$1"
  shift || true
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

PUBSPEC="$ROOT/pubspec.yaml"
PLIST="$ROOT/ios/Runner/Info.plist"

# ------------------------------------------
# Helper: print install suggestions
# ------------------------------------------
suggest_install() {
  local tool="$1"

  echo "The tool '$tool' is required but not installed." >&2
  echo "" >&2

  echo "→ Install on macOS (Homebrew):" >&2
  case "$tool" in
    yq)         echo "    brew install yq" >&2 ;;
    xmlstarlet) echo "    brew install xmlstarlet" >&2 ;;
    *)          echo "    brew install $tool" >&2 ;;
  esac

  echo "" >&2
  echo "→ Install on Debian/Ubuntu (APT):" >&2
  case "$tool" in
    yq)         echo "    sudo apt install yq" >&2 ;;
    xmlstarlet) echo "    sudo apt install xmlstarlet" >&2 ;;
    *)          echo "    sudo apt install $tool" >&2 ;;
  esac

  echo "" >&2
}

# ------------------------------------------
# Tool requirement checks
# ------------------------------------------
if ! yq --version >/dev/null 2>&1; then
  echo "[Error] yq is not installed." >&2
  suggest_install "yq"

  if command jq --version >/dev/null 2>&1; then
    echo "[Note] jq is installed but it cannot parse YAML." >&2
  fi

  exit 1
fi

if ! xmlstarlet --version >/dev/null 2>&1; then
  echo "[Error] xmlstarlet is not installed." >&2
  suggest_install "xmlstarlet"
  exit 1
fi

# ------------------------------------------
# File checks
# ------------------------------------------
if [[ ! -f "$PUBSPEC" ]]; then
  echo "[Error] pubspec not found: $PUBSPEC" >&2
  exit 1
fi

if [[ ! -f "$PLIST" ]]; then
  echo "[Error] Info.plist not found: $PLIST" >&2
  exit 1   # nothing to do
fi

# Check if pubspec.yaml has a non-empty plist: section
if ! yq -e '.plist // {} | length > 0' "$PUBSPEC" >/dev/null 2>&1; then
  exit 0   # no plist config -> nothing to sync
fi

# ------------------------------------------
# XML Escaping helper
# ------------------------------------------
xml_escape() {
  local s=$1
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  s=${s//\"/&quot;}
  echo "$s"
}

# ------------------------------------------
# Helper: does key exist in Info.plist?
# ------------------------------------------
key_exists() {
  local key="$1"
  local count
  count=$(xmlstarlet sel -t -v "count(/plist/dict/key[text()='$key'])" "$PLIST" 2>/dev/null || echo 0)
  [[ "$count" -ge 1 ]]
}

# Helper: get current string value for key (empty if none)
get_current_value() {
  local key="$1"
  xmlstarlet sel -t -v "/plist/dict/key[text()='$key']/following-sibling::string[1]" -n "$PLIST" 2>/dev/null || true
}

# ------------------------------------------
# Sync logic
# ------------------------------------------
# From pubspec.yaml -> plist entries
# We output: KEY<TAB>TYPE<TAB>VALUE
while IFS=$'\t' read -r KEY VTYPE VALUE; do
  KEY=$(echo "$KEY" | xargs)

  # YAML null → remove key + next <string> if present
  if [[ "$VTYPE" == "!!null" ]]; then
    if key_exists "$KEY"; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[Note] key ${KEY} would be removed (and its <string> value)"
      else
        # delete key and its following string in two steps (avoid union expressions)
        xmlstarlet ed -L \
          -d "/plist/dict/key[text()='$KEY']/following-sibling::string[1]" \
          "$PLIST"
        xmlstarlet ed -L \
          -d "/plist/dict/key[text()='$KEY']" \
          "$PLIST"
        echo "[Note] key ${KEY} has been removed (and its <string> value)"
      fi
    fi
    continue
  fi

  # Non-null → add/update
  VALUE_ESCAPED=$(xml_escape "$VALUE")

  if key_exists "$KEY"; then
    CURRENT_VALUE=$(get_current_value "$KEY")
    if [[ "$CURRENT_VALUE" == "$VALUE" ]]; then
      # No change needed
      if [[ "$DRY_RUN" -eq 1 ]]; then
        # Uncomment if you want to see no-op lines:
        echo "[Note] key ${KEY} already has desired value (no change)"
        :
      fi
    else
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[Note] string for key ${KEY} would be updated from \"${CURRENT_VALUE}\" to \"${VALUE}\""
      else
        xmlstarlet ed -L \
          -u "/plist/dict/key[text()='$KEY']/following-sibling::string[1]" \
          -v "$VALUE_ESCAPED" \
          "$PLIST"
        echo "[Note] string for key ${KEY} has been updated to \"${VALUE}\""
      fi
    fi
  else
    # Key does not exist yet
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[Note] key ${KEY} would be added with string \"${VALUE}\""
    else
      xmlstarlet ed -L \
        -a "/plist/dict/*[last()]" -t elem -n "key"    -v "$KEY" \
        -a "/plist/dict/*[last()]" -t elem -n "string" -v "$VALUE_ESCAPED" \
        "$PLIST"
        echo "[Note] key ${KEY} has been added with string \"${VALUE}\""
    fi
  fi
done < <(
  yq -r '.plist // {}
         | to_entries[]
         | [.key, (.value | type), (.value // "")]
         | @tsv' "$PUBSPEC"
)
