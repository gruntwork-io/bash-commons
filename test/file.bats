#!/usr/bin/env bats

readonly file_module_path="$BATS_TEST_DIRNAME/../modules/bash-commons/src/file.sh"
source "$file_module_path"
load "test-helper"

@test "file_exists on non-existent file" {
  run file_exists "not-a-real-file"
  assert_failure
}

@test "file_exists on real file" {
  run file_exists "$file_module_path"
  assert_success
}

@test "file_contains_text on non-existent file" {
  run file_contains_text "foo" "not-a-real-file"
  assert_failure
}

@test "file_contains_text no match" {
  run file_contains_text "this text is not in the file" "$file_module_path"
  assert_failure
}

@test "file_contains_text match" {
  run file_contains_text "file_contains_text" "$file_module_path"
  assert_success
}

@test "file_contains_text regex match" {
  run file_contains_text "file_.*_text" "$file_module_path"
  assert_success
}

@test "file_append_text once" {
  local readonly tmp_file=$(mktemp)
  local readonly text="foo"

  run file_append_text "$text" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  assert_equal "$text" "$actual"

  rm -f "$tmp_file"
}

@test "file_append_text multiple times" {
  local readonly tmp_file=$(mktemp)
  local readonly text="foo"
  local readonly expected=$(echo -e "$text\n$text\n$text")

  run file_append_text "$text" "$tmp_file"
  assert_success

  run file_append_text "$text" "$tmp_file"
  assert_success

  run file_append_text "$text" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_text empty file" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex="foo"
  local readonly replacement="bar"

  run file_replace_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected=""
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_text non empty file, no match" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex="foo"
  local readonly replacement="bar"
  local readonly file_contents="not a match"

  echo "$file_contents" > "$tmp_file"

  run file_replace_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected="$file_contents"
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_text non empty file, exact match" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex="abc foo def"
  local readonly replacement="bar"
  local readonly file_contents="abc foo def"

  echo "$file_contents" > "$tmp_file"

  run file_replace_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected="$replacement"
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_text non empty file, regex match" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex=".*foo.*"
  local readonly replacement="bar"
  local readonly file_contents="abc foo def"

  echo "$file_contents" > "$tmp_file"

  run file_replace_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected="$replacement"
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_text_in_files non empty files, regex match" {
  local tmp_file1=$(mktemp)
  local tmp_file2=$(mktemp)
  local -r original_regex=".*foo.*"
  local -r replacement="bar"
  local -r file_contents1="abc foo def"
  local -r file_contents2="baz foo fuzz"

  echo "$file_contents1" > "$tmp_file1"
  echo "$file_contents2" > "$tmp_file2"

  run file_replace_text_in_files "$original_regex" "$replacement" "$tmp_file1" "$tmp_file2"
  assert_success

  local actual1=$(cat "$tmp_file1")
  local actual2=$(cat "$tmp_file2")
  assert_equal "$replacement" "$actual1"
  assert_equal "$replacement" "$actual2"


  rm -f "$tmp_file1" "$tmp_file2"
}

@test "file_replace_or_append_text empty file" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex="foo"
  local readonly replacement="bar"

  run file_replace_or_append_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected="$replacement"
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_or_append_text non empty file, no match" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex="foo"
  local readonly replacement="bar"
  local readonly file_contents="not a match"

  echo "$file_contents" > "$tmp_file"

  run file_replace_or_append_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected=$(echo -e "$file_contents\n$replacement")
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_or_append_text non empty file, exact match" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex="foo"
  local readonly replacement="bar"
  local readonly file_contents="foo"

  echo "$file_contents" > "$tmp_file"

  run file_replace_or_append_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected=$(echo -e "$replacement")
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_replace_or_append_text non empty file, regex match one line" {
  local readonly tmp_file=$(mktemp)
  local readonly original_regex=".*foo.*"
  local readonly replacement="bar"
  local readonly file_contents=$(echo -e "abc\nblah foo blah\nbaz")

  echo "$file_contents" > "$tmp_file"

  run file_replace_or_append_text "$original_regex" "$replacement" "$tmp_file"
  assert_success

  local readonly actual=$(cat "$tmp_file")
  local readonly expected=$(echo -e "abc\n$replacement\nbaz")
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_fill_template non empty file, nothing to replace" {
  local -r tmp_file=$(mktemp)
  local -ar auto_fill=("<__PLACEHOLDER__>=hello")
  local -r file_contents=$(echo -e "abc\nhey world\nbaz")

  echo "$file_contents" > "$tmp_file"

  run file_fill_template "$tmp_file" "${auto_fill[@]}"
  assert_success

  local -r actual=$(cat "$tmp_file")
  local -r expected=$file_contents
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_fill_template non empty file, replace text" {
  local -r tmp_file=$(mktemp)
  local -ar auto_fill=("<__PLACEHOLDER__>=hello")
  local -r file_contents=$(echo -e "abc\n<__PLACEHOLDER__> world\nbaz")

  echo "$file_contents" > "$tmp_file"

  run file_fill_template "$tmp_file" "${auto_fill[@]}"
  assert_success

  local -r actual=$(cat "$tmp_file")
  local -r expected=$(echo -e "abc\nhello world\nbaz")
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}

@test "file_fill_template non empty file, replace multiple" {
  local -r tmp_file=$(mktemp)
  local -a auto_fill=("<__PLACEHOLDER__>=hello")
  auto_fill+=("<__PLACEHOLDER2__>=foo")

  local -r file_contents=$(echo -e "abc\n<__PLACEHOLDER__> world\n<__PLACEHOLDER2__> baz")

  echo "$file_contents" > "$tmp_file"

  run file_fill_template "$tmp_file" "${auto_fill[@]}"
  assert_success

  local -r actual=$(cat "$tmp_file")
  local -r expected=$(echo -e "abc\nhello world\nfoo baz")
  assert_equal "$expected" "$actual"

  rm -f "$tmp_file"
}
