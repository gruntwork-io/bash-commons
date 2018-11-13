#!/usr/bin/env bash

# shellcheck source=./modules/bash-commons/src/os.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../modules/bash-commons/src/bootstrap.sh"

function run_shellcheck {
  local -r format="${1}"
  shift
  local -i exit_code
  local -a results

  shellcheck --version
  echo

  printf "Shellcheck is scanning some files (%s):\n" "$#"
  printf "  %s\n" "$@"
  echo

  set +e
  IFS=$'\n' \
    read -ra results <<< \
      "$(shellcheck \
        --exclude=SC1117 \
        --external-sources \
        --format="$format" \
        "$@" 2>&1
      )"
  exit_code=$?
  set -e

  case "$exit_code" in
    0)
      echo "All files successfully scanned with no issues"
      ;;

    1)
      printf "All files successfully scanned with some issues (%s):\n" ${#results[@]}
      printf "  %s\n" "${results[@]}"
      exit $exit_code
      ;;

    2)
      printf "Some files could not be processed (%s):\n" ${#results[@]}
      printf "  %s\n" "${results[@]}"
      exit $exit_code
      ;;

    3)
      echo "ShellCheck was invoked with bad syntax:"
      printf "  %s\n" "${results[@]}"
      exit $exit_code
      ;;

    4)
      echo "ShellCheck was invoked with bad options:"
      printf "  %s\n" "${results[@]}"
      exit $exit_code
      ;;
           
    *)
      echo "Unrecognized exit code '$exit_code' returned from shellcheck"
      set -x
      exit 1
   
  esac
}

# Runs shellcheck against shell scripts and displays results.
# 
# format {1}: Shellcheck format options, either one of "tty", "gcc", "checkstyle"
#             or "json". Default is "gcc".
# filename {2}: If not given, it will search for all files whose first line
#               begin with a shebang like "#!/usr/bin/env bash".
#               If given a string of space separated files, only those files
#               will be scanned.
function main {
  local -a check_files
  local -r format="${1:-gcc}"
  local filename="${2:-}"
  local line

  # If `CIRCLE_WORKING_DIRECTORY` is not set, assume the project root dir.
  if [[ -z "${CIRCLE_WORKING_DIRECTORY:-}" ]]; then
    CIRCLE_WORKING_DIRECTORY="$(
      readlink -f \
        "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
    )"
  fi

  if [[ -z "$filename" ]]; then
    # Since no filenames are provided, look for files based on shebang.
    while read -r filename; do
      set +e
      IFS= read -rd '' line < <(head -n 1 "$filename")
      set -e

      if [[ "$line" =~ ^#!/usr/bin/env\ +bash ]]; then
        check_files+=( "$filename" )
      fi
    done < <(find "$CIRCLE_WORKING_DIRECTORY" -path ./.git -prune -o -type f -print)
  else
    check_files=( "$filename" )
  fi

  run_shellcheck "$format" "${check_files[@]}"
}

main "$@"
exit 0