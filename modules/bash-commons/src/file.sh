#!/usr/bin/env bash
# A collection of functions for working with files.

# shellcheck source=./modules/bash-commons/src/os.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/string.sh"

# Returns true (0) if the given file exists and is a file and false (1) otherwise
function file_exists {
  local -r file="$1"
  [[ -f "$file" ]]
}

# Returns true (0) if the given file exists contains the given text and false (1) otherwise. The given text is a
# regular expression.
function file_contains_text {
  local -r text="$1"
  local -r file="$2"
  grep -q "$text" "$file"
}

# Append the given text to the given file. The reason this method exists, as opposed to using bash's built-in append
# operator, is that this method uses sudo, which doesn't work natively with the built-in operator.
function file_append_text {
  local -r text="$1"
  local -r file="$2"

  echo -e "$text" | sudo tee -a "$file" > /dev/null
}

# Replace a line of text that matches the given regular expression in a file with the given replacement. Only works for
# single-line replacements. Note that this method uses sudo!
function file_replace_text {
  local -r original_text_regex="$1"
  local -r replacement_text="$2"
  local -r file="$3"

  local args=()
  args+=("-i")

  if os_is_darwin; then
    # OS X requires an extra argument for the -i flag (which we set to empty string) which Linux does no:
    # https://stackoverflow.com/a/2321958/483528
    args+=("")
  fi

  args+=("s|$original_text_regex|$replacement_text|")
  args+=("$file")

  sudo sed "${args[@]}" > /dev/null
}

# Call file_replace_text for each of the files listed in $files[@]
function file_replace_text_in_files {
  local -r original_text_regex="$1"
  local -r replacement_text="$2"
  shift 2
  local -ar files=("$@")

  for file in "${files[@]}"; do
    file_replace_text "$original_text_regex" "$replacement_text" "$file"
  done
}

# If the given file already contains the original text (which is a regex), replace it with the given replacement. If
# it doesn't contain that text, simply append the replacement text at the end of the file.
function file_replace_or_append_text {
  local -r original_text_regex="$1"
  local -r replacement_text="$2"
  local -r file="$3"

  if file_exists "$file" && file_contains_text "$original_text_regex" "$file"; then
    file_replace_text "$original_text_regex" "$replacement_text" "$file"
  else
    file_append_text "$replacement_text" "$file"
  fi
}

# Replace a specific template string in a file with a value. Provided as an array of TEMPLATE-STRING=VALUE
function file_fill_template {
  local -r file="$1"
  shift 1
  local -ar auto_fill=("$@")

  if [[ -z "${auto_fill[@]}" ]]; then
    log_info "No auto-fill params specified."
    return
  fi

  local name
  local value
  for param in "${auto_fill[@]}"; do
    name="$(string_strip_suffix "$param" "=*")"
    value="$(string_strip_prefix "$param" "*=")"
    file_replace_text "$name" "$value" "$file"
  done
}
