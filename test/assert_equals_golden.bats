#!/usr/bin/env bats

load test_helper

bats_require_minimum_version 1.5.0

test_temp_golden_file=''
save_temp_file_path_and_run() {
  local -r temp_file_arg="$#"

  test_temp_golden_file="${!temp_file_arg}"

  run "$@"
}

#
# assert_equals_golden
# Literal matching
#

@test "assert_equals_golden: succeeds if output and golden match" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden "$tested_value" <(printf 'a')
  assert_test_pass
}

@test "assert_equals_golden: succeeds if multiline output and golden match" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden "$tested_value" <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_equals_golden: succeeds if output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden "$tested_value" <(printf 'a\n')
  assert_test_pass
}

@test "assert_equals_golden: succeeds if multiline output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden "$tested_value" <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_equals_golden: fails if output and golden do not match" {
  run printf 'b'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden "$tested_value" <(printf 'a')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):
b
--
ERR_MSG
}

@test "assert_equals_golden: fails if output and golden do not match due to extra trailing newline" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden "$tested_value" <(printf 'a\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a

actual value (1 lines):
a
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: fails if multiline output and golden do not match due to extra trailing newline" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden "$tested_value" <(printf 'a\nb\nc\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c

actual value (3 lines):
a
b
c
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: fails if output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden "$tested_value" <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):
a

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: fails if multiline output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden "$tested_value" <(printf 'a\nb\nc')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c
actual value (3 lines):
a
b
c

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: succeeds if output is newline with newline golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden "$tested_value" <(printf '\n')

  assert_test_pass
}

@test "assert_equals_golden: fails if output is and golden are empty" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden "$tested_value" <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_equals_golden: succeeds if output is and golden are empty when allowed" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --allow-empty "$tested_value" <(:)

  assert_test_pass
}

@test "assert_equals_golden: succeeds if output is and golden are empty when allowed - kept empty lines" {
  run --keep-empty-lines :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --allow-empty "$tested_value" <(:)

  assert_test_pass
}

@test "assert_equals_golden: fails if output is newline with non-empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden "$tested_value" <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: fails if output is newline with allowed empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --allow-empty "$tested_value" <(:)

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: fails if output is empty with newline golden" {
  run :
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden "$tested_value" <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual value (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: fails if output is empty with newline golden - kept empty lines" {
  run --keep-empty-lines :
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden "$tested_value" <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual value (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden: fails with too few parameters" {
  run assert_equals_golden

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Incorrect number of arguments: 0. Expected 2 arguments.
--
ERR_MSG
}

@test "assert_equals_golden: fails with too many parameters" {
  run assert_equals_golden a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Incorrect number of arguments: 3. Expected 2 arguments.
--
ERR_MSG
}

@test "assert_equals_golden: fails with empty golden file path" {
  run assert_equals_golden 'abc' ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_equals_golden: fails with nonexistent golden file" {
  run assert_equals_golden 'abc' some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_equals_golden: fails with non-openable golden file" {
  run assert_equals_golden 'abc' .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_equals_golden: '--' stops parsing options" {
  run assert_equals_golden -- '--diff' <(printf '%s' '--diff')

  assert_test_pass
}

@test "assert_equals_golden: fails due to literal (non-wildcard) matching by default" {
  run printf 'b'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden "$tested_value" <(printf '*')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
*
actual value (1 lines):
b
--
ERR_MSG
}

@test "assert_equals_golden: fails due to literal (non-regex) matching by default" {
  run printf 'b'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden "$tested_value" <(printf '.*')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
.*
actual value (1 lines):
b
--
ERR_MSG
}

#
# assert_equals_golden
# Literal matching with stdin
#

@test "assert_equals_golden --stdin: succeeds if output and golden match" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin <(printf 'a') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if output and golden match with '-' arg" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden - <(printf 'a') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if multiline output and golden match" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin <(printf 'a\nb\nc') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if multiline output and golden match with '-' arg" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden - <(printf 'a\nb\nc') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin <(printf 'a\n') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if output and golden match and contain trailing newline with '-' arg" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden - <(printf 'a\n') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if multiline output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin <(printf 'a\nb\nc\n') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if multiline output and golden match and contain trailing newline with '-' arg" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden - <(printf 'a\nb\nc\n') < <(printf "$tested_value")
  assert_test_pass
}

@test "assert_equals_golden --stdin: fails if output and golden do not match" {
  run printf 'b'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --stdin <(printf 'a') < <(printf "$tested_value")

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):
b
--
ERR_MSG
}

@test "assert_equals_golden --stdin: fails if output and golden do not match with '-' arg" {
  run printf 'b'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden - <(printf 'a') < <(printf "$tested_value")

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):
b
--
ERR_MSG
}

@test "assert_equals_golden --stdin: fails if output and golden do not match due to extra trailing newline" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin <(printf 'a\n') < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a

actual value (1 lines):
a
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if multiline output and golden do not match due to extra trailing newline" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin <(printf 'a\nb\nc\n') < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c

actual value (3 lines):
a
b
c
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin <(printf 'a') < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):
a

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if multiline output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin <(printf 'a\nb\nc') < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c
actual value (3 lines):
a
b
c

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: succeeds if output is newline with newline golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin <(printf '\n') < <(printf "$tested_value")

  assert_test_pass
}

@test "assert_equals_golden --stdin: fails if output is and golden are empty" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin <(:) < <(printf "$tested_value")

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_equals_golden --stdin: succeeds if output is and golden are empty when allowed" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin --allow-empty <(:) < <(printf "$tested_value")

  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if output is and golden are empty when allowed with '-' arg" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --allow-empty - <(:) < <(printf "$tested_value")

  assert_test_pass
}

@test "assert_equals_golden --stdin: succeeds if output is and golden are empty when allowed - kept empty lines" {
  run --keep-empty-lines :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --stdin --allow-empty <(:) < <(printf "$tested_value")

  assert_test_pass
}

@test "assert_equals_golden --stdin: fails if output is newline with non-empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin <(printf 'a') < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if output is newline with non-empty golden with '-' arg" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden - <(printf 'a') < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if output is newline with allowed empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin --allow-empty <(:) < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if output is newline with allowed empty golden with '-' arg" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --allow-empty - <(:) < <(printf "$tested_value")

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if output is empty with newline golden" {
  run :
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin <(printf '\n') < <(printf "$tested_value")

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual value (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if output is empty with newline golden with '-' arg" {
  run :
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden - <(printf '\n') < <(printf "$tested_value")

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual value (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --stdin: fails if output is empty with newline golden - kept empty lines" {
  run --keep-empty-lines :
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --stdin <(printf '\n') < <(printf "$tested_value")

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual value (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

#
# assert_equals_golden
# Literal matching with diff output
#

@test "assert_equals_golden --diff: succeeds if output and golden match" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --diff "$tested_value" <(printf 'a')
  assert_test_pass
}

@test "assert_equals_golden --diff: succeeds if multiline output and golden match" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --diff "$tested_value" <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_equals_golden --diff: succeeds if output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --diff "$tested_value" <(printf 'a\n')
  assert_test_pass
}

@test "assert_equals_golden --diff: succeeds if multiline output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --diff "$tested_value" <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_equals_golden --diff: fails if output and golden do not match" {
  run printf 'b'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff "$tested_value" <(printf 'a')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
1c1
< b
---
> a
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails if output and golden do not match due to extra trailing newline" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff "$tested_value" <(printf 'a\n')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
1a2
> 
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails if multiline output and golden do not match due to extra trailing newline" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff "$tested_value" <(printf 'a\nb\nc\n')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
3a4
> 
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails if output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff "$tested_value" <(printf 'a')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
2d1
< 
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails if multiline output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff "$tested_value" <(printf 'a\nb\nc')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
4d3
< 
--
ERR_MSG
}

@test "assert_equals_golden --diff: succeeds if output is newline with newline golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --diff "$tested_value" <(printf '\n')

  assert_test_pass
}

@test "assert_equals_golden --diff: fails if output is and golden are empty" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --diff "$tested_value" <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_equals_golden --diff: succeeds if output is and golden are empty when allowed" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --diff --allow-empty "$tested_value" <(:)

  assert_test_pass
}

@test "assert_equals_golden --diff: fails if output is newline with non-empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff "$tested_value" <(printf 'a')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
1,2c1
< 
< 
---
> a
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails if output is newline with allowed empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff --allow-empty "$tested_value" <(:)

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
2d1
< 
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails if output is empty with newline golden" {
  run :
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --diff "$tested_value" <(printf '\n')

  assert_test_fail <<ERR_MSG

-- value does not match golden --
Golden file: $test_temp_golden_file
1a2
> 
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails with too few parameters" {
  run assert_equals_golden --diff

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Incorrect number of arguments: 0. Expected 2 arguments.
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails with too many parameters" {
  run assert_equals_golden --diff a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Incorrect number of arguments: 3. Expected 2 arguments.
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails with empty golden file path" {
  run assert_equals_golden --diff 'abc' ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails with nonexistent golden file" {
  run assert_equals_golden --diff 'abc' some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_equals_golden --diff: fails with non-openable golden file" {
  run assert_equals_golden --diff 'abc' .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_equals_golden --diff: '--' stops parsing options" {
  run assert_equals_golden --diff -- '--diff' <(printf '%s' '--diff')

  assert_test_pass
}

#
# assert_equals_golden
# Regex matching
#

@test "assert_equals_golden --regexp: succeeds if output and golden match" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf 'a')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds if multiline output and golden match" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds if output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf 'a\n')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds if multiline output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_equals_golden --regexp: fails if output and golden do not match" {
  run printf 'b'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --regexp "$tested_value" <(printf 'a')

  assert_test_fail <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):
b
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails if output and golden do not match due to extra trailing newline" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf 'a\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a

actual value (1 lines):
a
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails if multiline output and golden do not match due to extra trailing newline" {
  run printf 'a\nb\nc'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf 'a\nb\nc\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c

actual value (3 lines):
a
b
c
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails if output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):
a

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails if multiline output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf 'a\nb\nc')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c
actual value (3 lines):
a
b
c

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: succeeds if output is newline with newline golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '\n')

  assert_test_pass
}

@test "assert_equals_golden --regexp: fails if output is and golden are empty" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_equals_golden --regexp: succeeds if output is and golden are empty when allowed" {
  run :
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp --allow-empty "$tested_value" <(:)

  assert_test_pass
}

@test "assert_equals_golden --regexp: fails if output is newline with non-empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails if output is newline with allowed empty golden" {
  run --keep-empty-lines printf '\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp --allow-empty "$tested_value" <(:)

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual value (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails if output is empty with newline golden" {
  run :
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual value (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails with too few parameters" {
  run assert_equals_golden --regexp

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Incorrect number of arguments: 0. Expected 2 arguments.
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails with too many parameters" {
  run assert_equals_golden --regexp a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Incorrect number of arguments: 3. Expected 2 arguments.
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails with empty golden file path" {
  run assert_equals_golden --regexp 'abc' ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails with nonexistent golden file" {
  run assert_equals_golden --regexp 'abc' some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails with non-openable golden file" {
  run assert_equals_golden --regexp 'abc' .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_equals_golden --regexp: '--' stops parsing options" {
  run assert_equals_golden --regexp -- '--diff' <(printf '%s' '--diff')

  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with special characters" {
  run printf '[.?+'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '\\[\\.\\?\\+')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with non-specific matching regex" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '.')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline non-specific exact matching regex" {
  run printf 'a\nb'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '...')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline non-specific greedy matching regex" {
  run printf 'abc\nxyz'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '.*')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline non-specific non-newline matching regex" {
  run printf 'abc\nxyz'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[^\\n]+\n[^\\n]+')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with specific matching regex" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[a]')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline specific matching regex" {
  run printf 'a\nb'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[a]\n[b]')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline specific repeating matching regex" {
  run printf 'aabbcc\nxxyyzz'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[abc]+\n[xyz]+')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline specific matching regex with trailing newlines" {
  run --keep-empty-lines printf 'aabbcc\nxxyyzz\n\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[abc]+\n[xyz]+\n\n')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline specific matching regex with special characters" {
  run printf 'aabbcc\n[.?+\nxxyyzz'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[abc]+\n\\[\\.\\?\\+\n[xyz]+')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline specific matching regex with special characters and trailing newlines" {
  run --keep-empty-lines printf 'aabbcc\n[.?+\nxxyyzz\n\n'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[abc]+\n\\[\\.\\?\\+\n[xyz]+\n\n')
  assert_test_pass
}

@test "assert_equals_golden --regexp: succeeds with multiline start-end matching regex" {
  run printf 'abc\ndef\nxyz'
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf 'abc\n.*xyz')
  assert_test_pass
}

@test "assert_equals_golden --regexp: fails with non-specific non-matching regex - too many" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --regexp "$tested_value" <(printf '..')

  assert_test_fail <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
..
actual value (1 lines):
a
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails with non-specific non-matching regex - too few" {
  run printf 'ab'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --regexp "$tested_value" <(printf '.')

  assert_test_fail <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
.
actual value (1 lines):
ab
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails with specific non-matching regex" {
  run printf 'a'
  tested_value="$output"
  output='UNUSED'
  save_temp_file_path_and_run assert_equals_golden --regexp "$tested_value" <(printf '[b]')

  assert_test_fail <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
[b]
actual value (1 lines):
a
--
ERR_MSG
}

@test "assert_equals_golden --regexp: fails with multiline specific matching regex with extra trailing newlines" {
  run --keep-empty-lines printf 'aabbcc\nxxyyzz\n\n'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf '[abc]+\n[xyz]+')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (2 lines):
[abc]+
[xyz]+
actual value (3 lines):
aabbcc
xxyyzz


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails with multiline specific matching regex with missing trailing newlines" {
  run printf 'aabbcc\nxxyyzz'
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_equals_golden --regexp "$tested_value" <(printf '[abc]+\n[xyz]+\n\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
[abc]+
[xyz]+


actual value (2 lines):
aabbcc
xxyyzz
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_equals_golden --regexp: fails if regex golden is not a valid extended regular expression" {
  tested_value="$output"
  output='UNUSED'
  run assert_equals_golden --regexp "$tested_value" <(printf '[.*')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Invalid extended regular expression in golden file: `[.*'
--
ERR_MSG
}

#
# assert_equals_golden
# Misc Error Handling
#

@test "assert_equals_golden: fails with --regexp --diff" {
  run assert_equals_golden --regexp --diff 'abc' <(printf 'abc')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
`--diff' not supported with `--regexp'
--
ERR_MSG
}

@test "assert_equals_golden: fails with unknown option" {
  run assert_equals_golden --not-a-real-option 'abc' <(printf 'abc')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_equals_golden --
Unsupported flag '--not-a-real-option'.
--
ERR_MSG
}

#
# assert_output_equals_golden
# Literal matching
#

@test "assert_output_equals_golden: succeeds if output and golden match" {
  run printf 'a'
  run assert_output_equals_golden <(printf 'a')
  assert_test_pass
}

@test "assert_output_equals_golden: succeeds if multiline output and golden match" {
  run printf 'a\nb\nc'
  run assert_output_equals_golden <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_output_equals_golden: succeeds if output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\n'
  run assert_output_equals_golden <(printf 'a\n')
  assert_test_pass
}

@test "assert_output_equals_golden: succeeds if multiline output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  run assert_output_equals_golden <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_output_equals_golden: fails if output and golden do not match" {
  run printf 'b'
  save_temp_file_path_and_run assert_output_equals_golden <(printf 'a')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual output (1 lines):
b
--
ERR_MSG
}

@test "assert_output_equals_golden: fails if output and golden do not match due to extra trailing newline" {
  run printf 'a'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden <(printf 'a\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a

actual output (1 lines):
a
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: fails if multiline output and golden do not match due to extra trailing newline" {
  run printf 'a\nb\nc'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden <(printf 'a\nb\nc\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c

actual output (3 lines):
a
b
c
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: fails if output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual output (1 lines):
a

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: fails if multiline output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden <(printf 'a\nb\nc')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c
actual output (3 lines):
a
b
c

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: succeeds if output is newline with newline golden" {
  run --keep-empty-lines printf '\n'
  run assert_output_equals_golden <(printf '\n')

  assert_test_pass
}

@test "assert_output_equals_golden: fails if output is and golden are empty" {
  run :
  run assert_output_equals_golden <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_output_equals_golden: succeeds if output is and golden are empty when allowed" {
  run :
  run assert_output_equals_golden --allow-empty <(:)

  assert_test_pass
}

@test "assert_output_equals_golden: succeeds if output is and golden are empty when allowed - kept empty lines" {
  run --keep-empty-lines :
  run assert_output_equals_golden --allow-empty <(:)

  assert_test_pass
}

@test "assert_output_equals_golden: fails if output is newline with non-empty golden" {
  run --keep-empty-lines printf '\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual output (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: fails if output is newline with allowed empty golden" {
  run --keep-empty-lines printf '\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --allow-empty <(:)

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual output (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: fails if output is empty with newline golden" {
  run :
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual output (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: fails if output is empty with newline golden - kept empty lines" {
  run --keep-empty-lines :
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual output (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden: fails with too few parameters" {
  run assert_output_equals_golden

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Incorrect number of arguments: 0. Expected 1 argument.
--
ERR_MSG
}

@test "assert_output_equals_golden: fails with too many parameters" {
  run assert_output_equals_golden a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Incorrect number of arguments: 3. Expected 1 argument.
--
ERR_MSG
}

@test "assert_output_equals_golden: fails with empty golden file path" {
  run assert_output_equals_golden ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_output_equals_golden: fails with nonexistent golden file" {
  run assert_output_equals_golden some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_output_equals_golden: fails with non-openable golden file" {
  run assert_output_equals_golden .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_output_equals_golden: '--' stops parsing options" {
  run printf '%s' '--diff'
  run assert_output_equals_golden -- <(printf '%s' '--diff')

  assert_test_pass
}

@test "assert_output_equals_golden: fails due to literal (non-wildcard) matching by default" {
  run printf 'b'
  save_temp_file_path_and_run assert_output_equals_golden <(printf '*')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
*
actual output (1 lines):
b
--
ERR_MSG
}

@test "assert_output_equals_golden: fails due to literal (non-regex) matching by default" {
  run printf 'b'
  save_temp_file_path_and_run assert_output_equals_golden <(printf '.*')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
.*
actual output (1 lines):
b
--
ERR_MSG
}

#
# assert_output_equals_golden
# Literal matching with diff output
#

@test "assert_output_equals_golden --diff: succeeds if output and golden match" {
  run printf 'a'
  run assert_output_equals_golden  --diff <(printf 'a')
  assert_test_pass
}

@test "assert_output_equals_golden --diff: succeeds if multiline output and golden match" {
  run printf 'a\nb\nc'
  run assert_output_equals_golden --diff <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_output_equals_golden --diff: succeeds if output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\n'
  run assert_output_equals_golden --diff <(printf 'a\n')
  assert_test_pass
}

@test "assert_output_equals_golden --diff: succeeds if multiline output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  run assert_output_equals_golden --diff <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_output_equals_golden --diff: fails if output and golden do not match" {
  run printf 'b'
  save_temp_file_path_and_run assert_output_equals_golden --diff <(printf 'a')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
1c1
< b
---
> a
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails if output and golden do not match due to extra trailing newline" {
  run printf 'a'
  save_temp_file_path_and_run assert_output_equals_golden --diff <(printf 'a\n')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
1a2
> 
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails if multiline output and golden do not match due to extra trailing newline" {
  run printf 'a\nb\nc'
  save_temp_file_path_and_run assert_output_equals_golden --diff <(printf 'a\nb\nc\n')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
3a4
> 
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails if output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\n'
  save_temp_file_path_and_run assert_output_equals_golden --diff <(printf 'a')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
2d1
< 
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails if multiline output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  save_temp_file_path_and_run assert_output_equals_golden --diff <(printf 'a\nb\nc')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
4d3
< 
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: succeeds if output is newline with newline golden" {
  run --keep-empty-lines printf '\n'
  run assert_output_equals_golden --diff <(printf '\n')

  assert_test_pass
}

@test "assert_output_equals_golden --diff: fails if output is and golden are empty" {
  run :
  run assert_output_equals_golden --diff <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: succeeds if output is and golden are empty when allowed" {
  run :
  run assert_output_equals_golden --diff --allow-empty <(:)

  assert_test_pass
}

@test "assert_output_equals_golden --diff: fails if output is newline with non-empty golden" {
  run --keep-empty-lines printf '\n'
  save_temp_file_path_and_run assert_output_equals_golden --diff <(printf 'a')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
1,2c1
< 
< 
---
> a
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails if output is newline with allowed empty golden" {
  run --keep-empty-lines printf '\n'
  save_temp_file_path_and_run assert_output_equals_golden --diff --allow-empty <(:)

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
2d1
< 
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails if output is empty with newline golden" {
  run :
  save_temp_file_path_and_run assert_output_equals_golden --diff <(printf '\n')

  assert_test_fail <<ERR_MSG

-- output does not match golden --
Golden file: $test_temp_golden_file
1a2
> 
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails with too few parameters" {
  run assert_output_equals_golden --diff

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Incorrect number of arguments: 0. Expected 1 argument.
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails with too many parameters" {
  run assert_output_equals_golden --diff a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Incorrect number of arguments: 3. Expected 1 argument.
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails with empty golden file path" {
  run assert_output_equals_golden --diff ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails with nonexistent golden file" {
  run assert_output_equals_golden --diff some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: fails with non-openable golden file" {
  run assert_output_equals_golden --diff .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_output_equals_golden --diff: '--' stops parsing options" {
  run printf '%s' '--diff'
  run assert_output_equals_golden --diff -- <(printf '%s' '--diff')

  assert_test_pass
}

#
# assert_output_equals_golden
# Regex matching
#

@test "assert_output_equals_golden --regexp: succeeds if output and golden match" {
  run printf 'a'
  run assert_output_equals_golden  --regexp <(printf 'a')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds if multiline output and golden match" {
  run printf 'a\nb\nc'
  run assert_output_equals_golden --regexp <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds if output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\n'
  run assert_output_equals_golden --regexp <(printf 'a\n')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds if multiline output and golden match and contain trailing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  run assert_output_equals_golden --regexp <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: fails if output and golden do not match" {
  run printf 'b'
  save_temp_file_path_and_run assert_output_equals_golden --regexp <(printf 'a')

  assert_test_fail <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual output (1 lines):
b
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails if output and golden do not match due to extra trailing newline" {
  run printf 'a'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf 'a\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a

actual output (1 lines):
a
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails if multiline output and golden do not match due to extra trailing newline" {
  run printf 'a\nb\nc'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf 'a\nb\nc\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c

actual output (3 lines):
a
b
c
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails if output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual output (1 lines):
a

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails if multiline output and golden do not match due to extra missing newline" {
  run --keep-empty-lines printf 'a\nb\nc\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf 'a\nb\nc')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c
actual output (3 lines):
a
b
c

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: succeeds if output is newline with newline golden" {
  run --keep-empty-lines printf '\n'
  run assert_output_equals_golden --regexp <(printf '\n')

  assert_test_pass
}

@test "assert_output_equals_golden --regexp: fails if output is and golden are empty" {
  run :
  run assert_output_equals_golden --regexp <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: succeeds if output is and golden are empty when allowed" {
  run :
  run assert_output_equals_golden --regexp --allow-empty <(:)

  assert_test_pass
}

@test "assert_output_equals_golden --regexp: fails if output is newline with non-empty golden" {
  run --keep-empty-lines printf '\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual output (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails if output is newline with allowed empty golden" {
  run --keep-empty-lines printf '\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp --allow-empty <(:)

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual output (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails if output is empty with newline golden" {
  run :
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual output (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails with too few parameters" {
  run assert_output_equals_golden --regexp

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Incorrect number of arguments: 0. Expected 1 argument.
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails with too many parameters" {
  run assert_output_equals_golden --regexp a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Incorrect number of arguments: 3. Expected 1 argument.
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails with empty golden file path" {
  run assert_output_equals_golden --regexp ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails with nonexistent golden file" {
  run assert_output_equals_golden --regexp some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails with non-openable golden file" {
  run assert_output_equals_golden --regexp .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: '--' stops parsing options" {
  run printf '%s' '--diff'
  run assert_output_equals_golden --regexp -- <(printf '%s' '--diff')

  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with special characters" {
  run printf '[.?+'
  run assert_output_equals_golden --regexp <(printf '\\[\\.\\?\\+')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with non-specific matching regex" {
  run printf 'a'
  run assert_output_equals_golden --regexp <(printf '.')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline non-specific exact matching regex" {
  run printf 'a\nb'
  run assert_output_equals_golden --regexp <(printf '...')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline non-specific greedy matching regex" {
  run printf 'abc\nxyz'
  run assert_output_equals_golden --regexp <(printf '.*')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline non-specific non-newline matching regex" {
  run printf 'abc\nxyz'
  run assert_output_equals_golden --regexp <(printf '[^\\n]+\n[^\\n]+')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with specific matching regex" {
  run printf 'a'
  run assert_output_equals_golden --regexp <(printf '[a]')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline specific matching regex" {
  run printf 'a\nb'
  run assert_output_equals_golden --regexp <(printf '[a]\n[b]')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline specific repeating matching regex" {
  run printf 'aabbcc\nxxyyzz'
  run assert_output_equals_golden --regexp <(printf '[abc]+\n[xyz]+')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline specific matching regex with trailing newlines" {
  run --keep-empty-lines printf 'aabbcc\nxxyyzz\n\n'
  run assert_output_equals_golden --regexp <(printf '[abc]+\n[xyz]+\n\n')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline specific matching regex with special characters" {
  run printf 'aabbcc\n[.?+\nxxyyzz'
  run assert_output_equals_golden --regexp <(printf '[abc]+\n\\[\\.\\?\\+\n[xyz]+')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline specific matching regex with special characters and trailing newlines" {
  run --keep-empty-lines printf 'aabbcc\n[.?+\nxxyyzz\n\n'
  run assert_output_equals_golden --regexp <(printf '[abc]+\n\\[\\.\\?\\+\n[xyz]+\n\n')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: succeeds with multiline start-end matching regex" {
  run printf 'abc\ndef\nxyz'
  run assert_output_equals_golden --regexp <(printf 'abc\n.*xyz')
  assert_test_pass
}

@test "assert_output_equals_golden --regexp: fails with non-specific non-matching regex - too many" {
  run printf 'a'
  save_temp_file_path_and_run assert_output_equals_golden --regexp <(printf '..')

  assert_test_fail <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
..
actual output (1 lines):
a
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails with non-specific non-matching regex - too few" {
  run printf 'ab'
  save_temp_file_path_and_run assert_output_equals_golden --regexp <(printf '.')

  assert_test_fail <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
.
actual output (1 lines):
ab
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails with specific non-matching regex" {
  run printf 'a'
  save_temp_file_path_and_run assert_output_equals_golden --regexp <(printf '[b]')

  assert_test_fail <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
[b]
actual output (1 lines):
a
--
ERR_MSG
}

@test "assert_output_equals_golden --regexp: fails with multiline specific matching regex with extra trailing newlines" {
  run --keep-empty-lines printf 'aabbcc\nxxyyzz\n\n'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf '[abc]+\n[xyz]+')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (2 lines):
[abc]+
[xyz]+
actual output (3 lines):
aabbcc
xxyyzz


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails with multiline specific matching regex with missing trailing newlines" {
  run printf 'aabbcc\nxxyyzz'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_output_equals_golden --regexp <(printf '[abc]+\n[xyz]+\n\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
[abc]+
[xyz]+


actual output (2 lines):
aabbcc
xxyyzz
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_output_equals_golden --regexp: fails if regex golden is not a valid extended regular expression" {
  run assert_output_equals_golden --regexp <(printf '[.*')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Invalid extended regular expression in golden file: `[.*'
--
ERR_MSG
}

#
# assert_output_equals_golden
# Misc Error Handling
#

@test "assert_output_equals_golden: fails with --regexp --diff" {
  run assert_output_equals_golden --regexp --diff <(printf 'abc')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
`--diff' not supported with `--regexp'
--
ERR_MSG
}

@test "assert_output_equals_golden: fails with unknown option" {
  run assert_output_equals_golden --not-a-real-option <(printf 'abc')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_output_equals_golden --
Unsupported flag '--not-a-real-option'.
--
ERR_MSG
}

#
# assert_file_equals_golden
# Literal matching
#

@test "assert_file_equals_golden: succeeds if output and golden match" {
  run assert_file_equals_golden <(printf 'a') <(printf 'a')
  assert_test_pass
}

@test "assert_file_equals_golden: succeeds if multiline output and golden match" {
  run assert_file_equals_golden <(printf 'a\nb\nc') <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_file_equals_golden: succeeds if output and golden match and contain trailing newline" {
  run assert_file_equals_golden <(printf 'a\n') <(printf 'a\n')
  assert_test_pass
}

@test "assert_file_equals_golden: succeeds if multiline output and golden match and contain trailing newline" {
  run assert_file_equals_golden <(printf 'a\nb\nc\n') <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_file_equals_golden: fails if output and golden do not match" {
  save_temp_file_path_and_run assert_file_equals_golden <(printf 'b') <(printf 'a')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual file contents (1 lines):
b
--
ERR_MSG
}

@test "assert_file_equals_golden: fails if output and golden do not match due to extra trailing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden <(printf 'a') <(printf 'a\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a

actual file contents (1 lines):
a
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden: fails if multiline output and golden do not match due to extra trailing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden <(printf 'a\nb\nc') <(printf 'a\nb\nc\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c

actual file contents (3 lines):
a
b
c
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden: fails if output and golden do not match due to extra missing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden <(printf 'a\n') <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual file contents (1 lines):
a

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden: fails if multiline output and golden do not match due to extra missing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden <(printf 'a\nb\nc\n') <(printf 'a\nb\nc')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c
actual file contents (3 lines):
a
b
c

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden: succeeds if output is newline with newline golden" {
  run assert_file_equals_golden <(printf '\n') <(printf '\n')

  assert_test_pass
}

@test "assert_file_equals_golden: fails if output is and golden are empty" {
  run assert_file_equals_golden <(:) <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_file_equals_golden: succeeds if output is and golden are empty when allowed" {
  run assert_file_equals_golden --allow-empty <(:) <(:)

  assert_test_pass
}

@test "assert_file_equals_golden: fails if output is newline with non-empty golden" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden <(printf '\n') <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual file contents (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden: fails if output is newline with allowed empty golden" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --allow-empty <(printf '\n') <(:)

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual file contents (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden: fails if output is empty with newline golden" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden <(:) <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual file contents (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden: fails with too few parameters" {
  run assert_file_equals_golden

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Incorrect number of arguments: 0. Expected 2 argument.
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with too many parameters" {
  run assert_file_equals_golden a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Incorrect number of arguments: 3. Expected 2 argument.
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with empty target file path" {
  run assert_file_equals_golden '' <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Target file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with empty golden file path" {
  run assert_file_equals_golden <(print 'a') ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with nonexistent target file" {
  run assert_file_equals_golden some/path/this_file_definitely_does_not_exist.txt <(print 'a') 

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Target file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with nonexistent golden file" {
  run assert_file_equals_golden <(print 'a') some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with non-openable target file" {
  run assert_file_equals_golden . <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Failed to read target file. File path: '.'
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with non-openable golden file" {
  run assert_file_equals_golden <(print 'a') .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_file_equals_golden: '--' stops parsing options" {
  run assert_file_equals_golden -- <(printf '%s' '--diff') <(printf '%s' '--diff')

  assert_test_pass
}

@test "assert_file_equals_golden: fails due to literal (non-wildcard) matching by default" {
  save_temp_file_path_and_run assert_file_equals_golden <(printf 'b') <(printf '*')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
*
actual file contents (1 lines):
b
--
ERR_MSG
}

@test "assert_file_equals_golden: fails due to literal (non-regex) matching by default" {
  save_temp_file_path_and_run assert_file_equals_golden <(printf 'b') <(printf '.*')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
.*
actual file contents (1 lines):
b
--
ERR_MSG
}

#
# assert_file_equals_golden
# Literal matching with diff output
#

@test "assert_file_equals_golden --diff: succeeds if output and golden match" {
  run assert_file_equals_golden --diff <(printf 'a') <(printf 'a')
  assert_test_pass
}

@test "assert_file_equals_golden --diff: succeeds if multiline output and golden match" {
  run assert_file_equals_golden --diff <(printf 'a\nb\nc') <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_file_equals_golden --diff: succeeds if output and golden match and contain trailing newline" {
  run assert_file_equals_golden --diff <(printf 'a\n') <(printf 'a\n')
  assert_test_pass
}

@test "assert_file_equals_golden --diff: succeeds if multiline output and golden match and contain trailing newline" {
  run assert_file_equals_golden --diff <(printf 'a\nb\nc\n') <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_file_equals_golden --diff: fails if output and golden do not match" {
  save_temp_file_path_and_run assert_file_equals_golden --diff <(printf 'b') <(printf 'a')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
1c1
< b
---
> a
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails if output and golden do not match due to extra trailing newline" {
  save_temp_file_path_and_run assert_file_equals_golden --diff <(printf 'a') <(printf 'a\n')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
1a2
> 
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails if multiline output and golden do not match due to extra trailing newline" {
  save_temp_file_path_and_run assert_file_equals_golden --diff <(printf 'a\nb\nc') <(printf 'a\nb\nc\n')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
3a4
> 
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails if output and golden do not match due to extra missing newline" {
  save_temp_file_path_and_run assert_file_equals_golden --diff <(printf 'a\n') <(printf 'a')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
2d1
< 
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails if multiline output and golden do not match due to extra missing newline" {
  save_temp_file_path_and_run assert_file_equals_golden --diff <(printf 'a\nb\nc\n') <(printf 'a\nb\nc')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
4d3
< 
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: succeeds if output is newline with newline golden" {
  run assert_file_equals_golden --diff <(printf '\n') <(printf '\n')

  assert_test_pass
}

@test "assert_file_equals_golden --diff: fails if output is and golden are empty" {
  run assert_file_equals_golden --diff <(:) <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: succeeds if output is and golden are empty when allowed" {
  run assert_file_equals_golden --diff --allow-empty <(:) <(:)

  assert_test_pass
}

@test "assert_file_equals_golden --diff: fails if output is newline with non-empty golden" {
  save_temp_file_path_and_run assert_file_equals_golden --diff <(printf '\n') <(printf 'a')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
1,2c1
< 
< 
---
> a
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails if output is newline with allowed empty golden" {
  save_temp_file_path_and_run assert_file_equals_golden --diff --allow-empty <(printf '\n') <(:)

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
2d1
< 
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails if output is empty with newline golden" {
  save_temp_file_path_and_run assert_file_equals_golden --diff <(:) <(printf '\n')

  assert_test_fail <<ERR_MSG

-- file contents does not match golden --
Golden file: $test_temp_golden_file
1a2
> 
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with too few parameters" {
  run assert_file_equals_golden --diff

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Incorrect number of arguments: 0. Expected 2 argument.
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with too many parameters" {
  run assert_file_equals_golden --diff a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Incorrect number of arguments: 3. Expected 2 argument.
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with empty target file path" {
  run assert_file_equals_golden --diff '' <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Target file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with empty golden file path" {
  run assert_file_equals_golden --diff <(print 'a') ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with nonexistent target file" {
  run assert_file_equals_golden --diff some/path/this_file_definitely_does_not_exist.txt <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Target file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with nonexistent golden file" {
  run assert_file_equals_golden --diff <(print 'a') some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with non-openable target file" {
  run assert_file_equals_golden --diff . <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Failed to read target file. File path: '.'
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: fails with non-openable golden file" {
  run assert_file_equals_golden --diff <(print 'a') .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_file_equals_golden --diff: '--' stops parsing options" {
  run assert_file_equals_golden --diff -- <(printf '%s' '--diff') <(printf '%s' '--diff')

  assert_test_pass
}

#
# assert_file_equals_golden
# Regex matching
#

@test "assert_file_equals_golden --regexp: succeeds if output and golden match" {
  run assert_file_equals_golden  --regexp <(printf 'a') <(printf 'a')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds if multiline output and golden match" {
  run assert_file_equals_golden --regexp <(printf 'a\nb\nc') <(printf 'a\nb\nc')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds if output and golden match and contain trailing newline" {
  run assert_file_equals_golden --regexp <(printf 'a\n') <(printf 'a\n')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds if multiline output and golden match and contain trailing newline" {
  run assert_file_equals_golden --regexp <(printf 'a\nb\nc\n') <(printf 'a\nb\nc\n')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: fails if output and golden do not match" {
  save_temp_file_path_and_run assert_file_equals_golden --regexp <(printf 'b') <(printf 'a')

  assert_test_fail <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual file contents (1 lines):
b
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails if output and golden do not match due to extra trailing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(printf 'a') <(printf 'a\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a

actual file contents (1 lines):
a
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails if multiline output and golden do not match due to extra trailing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(printf 'a\nb\nc') <(printf 'a\nb\nc\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c

actual file contents (3 lines):
a
b
c
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails if output and golden do not match due to extra missing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(printf 'a\n') <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual file contents (1 lines):
a

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails if multiline output and golden do not match due to extra missing newline" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(printf 'a\nb\nc\n') <(printf 'a\nb\nc')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
a
b
c
actual file contents (3 lines):
a
b
c

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: succeeds if output is newline with newline golden" {
  run assert_file_equals_golden --regexp <(printf '\n') <(printf '\n')

  assert_test_pass
}

@test "assert_file_equals_golden --regexp: fails if output is and golden are empty" {
  run assert_file_equals_golden --regexp <(:) <(:)

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file contents is empty. This may be an authoring error. Use `--allow-empty` if this is intentional.
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: succeeds if output is and golden are empty when allowed" {
  run assert_file_equals_golden --regexp --allow-empty <(:) <(:)

  assert_test_pass
}

@test "assert_file_equals_golden --regexp: fails if output is newline with non-empty golden" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(printf '\n') <(printf 'a')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
a
actual file contents (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails if output is newline with allowed empty golden" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp --allow-empty <(printf '\n') <(:)

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (0 lines):

actual file contents (1 lines):


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails if output is empty with newline golden" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(:) <(printf '\n')

  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):


actual file contents (0 lines):

--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails with too few parameters" {
  run assert_file_equals_golden --regexp

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Incorrect number of arguments: 0. Expected 2 argument.
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with too many parameters" {
  run assert_file_equals_golden --regexp a b c

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Incorrect number of arguments: 3. Expected 2 argument.
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with empty target file path" {
  run assert_file_equals_golden --regexp '' <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Target file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with empty golden file path" {
  run assert_file_equals_golden --regexp <(print 'a') ''

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file path was not given or it was empty.
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with nonexistent target file" {
  run assert_file_equals_golden --regexp some/path/this_file_definitely_does_not_exist.txt <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Target file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with nonexistent golden file" {
  run assert_file_equals_golden --regexp <(print 'a') some/path/this_file_definitely_does_not_exist.txt

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Golden file was not found. File path: 'some/path/this_file_definitely_does_not_exist.txt'
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with non-openable target file" {
  run assert_file_equals_golden --regexp . <(print 'a')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Failed to read target file. File path: '.'
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with non-openable golden file" {
  run assert_file_equals_golden --regexp <(print 'a') .

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Failed to read golden file. File path: '.'
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: '--' stops parsing options" {
  run assert_file_equals_golden --regexp -- <(printf '%s' '--diff') <(printf '%s' '--diff')

  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with special characters" {
  run assert_file_equals_golden --regexp <(printf '[.?+') <(printf '\\[\\.\\?\\+')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with non-specific matching regex" {
  run assert_file_equals_golden --regexp <(printf 'a') <(printf '.')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline non-specific exact matching regex" {
  run assert_file_equals_golden --regexp <(printf 'a\nb') <(printf '...')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline non-specific greedy matching regex" {
  run assert_file_equals_golden --regexp <(printf 'abc\nxyz') <(printf '.*')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline non-specific non-newline matching regex" {
  run assert_file_equals_golden --regexp <(printf 'abc\nxyz') <(printf '[^\\n]+\n[^\\n]+')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with specific matching regex" {
  run assert_file_equals_golden --regexp <(printf 'a') <(printf '[a]')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline specific matching regex" {
  run assert_file_equals_golden --regexp <(printf 'a\nb') <(printf '[a]\n[b]')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline specific repeating matching regex" {
  run assert_file_equals_golden --regexp <(printf 'aabbcc\nxxyyzz') <(printf '[abc]+\n[xyz]+')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline specific matching regex with trailing newlines" {
  run assert_file_equals_golden --regexp <(printf 'aabbcc\nxxyyzz\n\n') <(printf '[abc]+\n[xyz]+\n\n')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline specific matching regex with special characters" {
  run assert_file_equals_golden --regexp <(printf 'aabbcc\n[.?+\nxxyyzz') <(printf '[abc]+\n\\[\\.\\?\\+\n[xyz]+')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline specific matching regex with special characters and trailing newlines" {
  run assert_file_equals_golden --regexp <(printf 'aabbcc\n[.?+\nxxyyzz\n\n') <(printf '[abc]+\n\\[\\.\\?\\+\n[xyz]+\n\n')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: succeeds with multiline start-end matching regex" {
  run assert_file_equals_golden --regexp <(printf 'abc\ndef\nxyz') <(printf 'abc\n.*xyz')
  assert_test_pass
}

@test "assert_file_equals_golden --regexp: fails with non-specific non-matching regex - too many" {
  save_temp_file_path_and_run assert_file_equals_golden --regexp <(printf 'a') <(printf '..')

  assert_test_fail <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
..
actual file contents (1 lines):
a
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with non-specific non-matching regex - too few" {
  save_temp_file_path_and_run assert_file_equals_golden --regexp <(printf 'ab') <(printf '.')

  assert_test_fail <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
.
actual file contents (1 lines):
ab
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with specific non-matching regex" {
  save_temp_file_path_and_run assert_file_equals_golden --regexp <(printf 'a') <(printf '[b]')

  assert_test_fail <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (1 lines):
[b]
actual file contents (1 lines):
a
--
ERR_MSG
}

@test "assert_file_equals_golden --regexp: fails with multiline specific matching regex with extra trailing newlines" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(printf 'aabbcc\nxxyyzz\n\n') <(printf '[abc]+\n[xyz]+')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix output "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (2 lines):
[abc]+
[xyz]+
actual file contents (3 lines):
aabbcc
xxyyzz


--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails with multiline specific matching regex with missing trailing newlines" {
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  save_temp_file_path_and_run --keep-empty-lines assert_file_equals_golden --regexp <(printf 'aabbcc\nxxyyzz') <(printf '[abc]+\n[xyz]+\n\n')

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $test_temp_golden_file
golden contents (3 lines):
[abc]+
[xyz]+


actual file contents (2 lines):
aabbcc
xxyyzz
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "assert_file_equals_golden --regexp: fails if regex golden is not a valid extended regular expression" {
  run assert_file_equals_golden --regexp <(printf 'abc') <(printf '[.*')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Invalid extended regular expression in golden file: `[.*'
--
ERR_MSG
}

#
# assert_file_equals_golden
# Misc Error Handling
#

@test "assert_file_equals_golden: fails with --regexp --diff" {
  run assert_file_equals_golden --regexp --diff <(printf 'abc') <(printf 'abc')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
`--diff' not supported with `--regexp'
--
ERR_MSG
}

@test "assert_file_equals_golden: fails with unknown option" {
  run assert_file_equals_golden --not-a-real-option <(printf 'abc') <(printf 'abc')

  assert_test_fail <<'ERR_MSG'

-- ERROR: assert_file_equals_golden --
Unsupported flag '--not-a-real-option'.
--
ERR_MSG
}

#
# Automatic golden file updating
#

@test "auto-update: assert_equals_golden: updates golden for failure" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual value (1 lines):
abc
--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$tested_output" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_equals_golden: failure if golden file is not writable" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]
  chmod a-w "$temp_golden_file"

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual value (1 lines):
abc
--


-- FAIL: assert_equals_golden --
Failed to write into golden file during update: '$temp_golden_file'.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "auto-update: assert_equals_golden: updates golden for failure multiline with trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual value (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$(printf "$tested_output")" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_equals_golden --regexp: updates golden for failure" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual value (1 lines):
abc
--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$tested_output" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_equals_golden --regexp: failure if golden file is not writable" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]
  chmod a-w "$temp_golden_file"

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual value (1 lines):
abc
--


-- FAIL: assert_equals_golden --
Failed to write into golden file during update: '$temp_golden_file'.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "auto-update: assert_equals_golden --regexp: updates golden for failure multiline with trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual value (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$(printf "$tested_output")" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_equals_golden --regexp: updates golden for failure multiline with regex and trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual value (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n[d-l]{3}\n\n[^a].[op]\n\n')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_equals_golden --regexp: updates golden for failure multiline with regex and special chars" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\n].{\njkl\n\nmno'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual value (7 lines):
abc
def
ghi
].{
jkl

mno
--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n\\]\\.\\{\n[d-l]{3}\n\n[^a].[op]')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_equals_golden --regexp: updates golden for failure multiline with regex, special chars, and trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\n].{\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual value (8 lines):
abc
def
ghi
].{
jkl

mno


--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n\\]\\.\\{\n[d-l]{3}\n\n[^a].[op]\n\n')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_equals_golden --regexp: updates golden for failure all special characters" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='[]\n.\n()\n*\n+\n?\n{}\n|\n^\n$\n\\ '

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  tested_value="$output"
  output='UNUSED'
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- value does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual value (11 lines):
[]
.
()
*
+
?
{}
|
^
$
\\ 
--


-- FAIL: assert_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '\\[\\]\n\\.\n\\(\\)\n\\*\n\\+\n\\?\n\\{\\}\n\\|\n\\^\n\\$\n\\\\ ')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_equals_golden --regexp "$tested_value" "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden: updates golden for failure" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual output (1 lines):
abc
--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$tested_output" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run printf "$tested_output"
  run assert_output_equals_golden "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden: failure if golden file is not writable" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]
  chmod a-w "$temp_golden_file"

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual output (1 lines):
abc
--


-- FAIL: assert_output_equals_golden --
Failed to write into golden file during update: '$temp_golden_file'.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "auto-update: assert_output_equals_golden: updates golden for failure multiline with trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual output (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$(printf "$tested_output")" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run --keep-empty-lines printf "$tested_output"
  run assert_output_equals_golden "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden --regexp: updates golden for failure" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden --regexp "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual output (1 lines):
abc
--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$tested_output" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run printf "$tested_output"
  run assert_output_equals_golden --regexp "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden --regexp: failure if golden file is not writable" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]
  chmod a-w "$temp_golden_file"

  tested_output='abc'

  run printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden --regexp "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual output (1 lines):
abc
--


-- FAIL: assert_output_equals_golden --
Failed to write into golden file during update: '$temp_golden_file'.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "auto-update: assert_output_equals_golden --regexp: updates golden for failure multiline with trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden --regexp "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual output (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$(printf "$tested_output")" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run --keep-empty-lines printf "$tested_output"
  run assert_output_equals_golden --regexp "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden --regexp: updates golden for failure multiline with regex and trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden --regexp "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual output (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n[d-l]{3}\n\n[^a].[op]\n\n')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run --keep-empty-lines printf "$tested_output"
  run assert_output_equals_golden --regexp "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden --regexp: updates golden for failure multiline with regex and special chars" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\n].{\njkl\n\nmno'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden --regexp "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual output (7 lines):
abc
def
ghi
].{
jkl

mno
--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n\\]\\.\\{\n[d-l]{3}\n\n[^a].[op]')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run --keep-empty-lines printf "$tested_output"
  run assert_output_equals_golden --regexp "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden --regexp: updates golden for failure multiline with regex, special chars, and trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\n].{\njkl\n\nmno\n\n'

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden --regexp "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual output (8 lines):
abc
def
ghi
].{
jkl

mno


--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n\\]\\.\\{\n[d-l]{3}\n\n[^a].[op]\n\n')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run --keep-empty-lines printf "$tested_output"
  run assert_output_equals_golden --regexp "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_output_equals_golden --regexp: updates golden for failure all special characters" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='[]\n.\n()\n*\n+\n?\n{}\n|\n^\n$\n\\ '

  run --keep-empty-lines printf "$tested_output"
  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_output_equals_golden --regexp "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- output does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual output (11 lines):
[]
.
()
*
+
?
{}
|
^
$
\\ 
--


-- FAIL: assert_output_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '\\[\\]\n\\.\n\\(\\)\n\\*\n\\+\n\\?\n\\{\\}\n\\|\n\\^\n\\$\n\\\\ ')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run --keep-empty-lines printf "$tested_output"
  run assert_output_equals_golden --regexp "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden: updates golden for failure" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual file contents (1 lines):
abc
--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$tested_output" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden: failure if golden file is not writable" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]
  chmod a-w "$temp_golden_file"

  tested_output='abc'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual file contents (1 lines):
abc
--


-- FAIL: assert_file_equals_golden --
Failed to write into golden file during update: '$temp_golden_file'.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "auto-update: assert_file_equals_golden: updates golden for failure multiline with trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual file contents (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$(printf "$tested_output")" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden --regexp: updates golden for failure" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual file contents (1 lines):
abc
--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$tested_output" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden --regexp: failure if golden file is not writable" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]
  chmod a-w "$temp_golden_file"

  tested_output='abc'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual file contents (1 lines):
abc
--


-- FAIL: assert_file_equals_golden --
Failed to write into golden file during update: '$temp_golden_file'.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"
}

@test "auto-update: assert_file_equals_golden --regexp: updates golden for failure multiline with trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf 'wrong output' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = 'wrong output' ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $temp_golden_file
golden contents (1 lines):
wrong output
actual file contents (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  [ "$(cat "$temp_golden_file")" = "$(printf "$tested_output")" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden --regexp: updates golden for failure multiline with regex and trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\njkl\n\nmno\n\n'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual file contents (7 lines):
abc
def
ghi
jkl

mno


--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n[d-l]{3}\n\n[^a].[op]\n\n')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden --regexp: updates golden for failure multiline with regex and special chars" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\n].{\njkl\n\nmno'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual file contents (7 lines):
abc
def
ghi
].{
jkl

mno
--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n\\]\\.\\{\n[d-l]{3}\n\n[^a].[op]')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden --regexp: updates golden for failure multiline with regex, special chars, and trailing newlines" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='abc\ndef\nghi\n].{\njkl\n\nmno\n\n'

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual file contents (8 lines):
abc
def
ghi
].{
jkl

mno


--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf 'abc\n[d-l]{3}\n[d-l]{3}\n\\]\\.\\{\n[d-l]{3}\n\n[^a].[op]\n\n')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}

@test "auto-update: assert_file_equals_golden --regexp: updates golden for failure all special characters" {
  temp_golden_file="$(mktemp -t "bats_test_${BATS_TEST_NUMBER}.XXXXXXXX.txt")"
  [ -f "$temp_golden_file" ]
  printf '[^a].[op]\n[d-l]{3}' > "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '[^a].[op]\n[d-l]{3}')" ]

  tested_output='[]\n.\n()\n*\n+\n?\n{}\n|\n^\n$\n\\ '

  BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE=1
  # Need to use `--keep-empty-lines` so that `${#lines[@]}` and `num_lines` can match in `assert_test_fail`.
  run --keep-empty-lines assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  # TODO(https://github.com/bats-core/bats-support/issues/11): Fix golden "lines" count in expected message.
  # Need to use variable to match trailing end lines caused by using `--keep-empty-lines`.
  expected="$(cat <<ERR_MSG

-- file contents does not match regexp golden --
Golden file: $temp_golden_file
golden contents (2 lines):
[^a].[op]
[d-l]{3}
actual file contents (11 lines):
[]
.
()
*
+
?
{}
|
^
$
\\ 
--


-- FAIL: assert_file_equals_golden --
Golden file updated after mismatch.
--

ERR_MSG
    printf '.')"
  expected="${expected%.}"
  assert_test_fail "$expected"

  cat "$temp_golden_file"
  [ "$(cat "$temp_golden_file")" = "$(printf '\\[\\]\n\\.\n\\(\\)\n\\*\n\\+\n\\?\n\\{\\}\n\\|\n\\^\n\\$\n\\\\ ')" ]
  unset BATS_ASSERT_UPDATE_GOLDENS_ON_FAILURE
  run assert_file_equals_golden --regexp <(printf "$tested_output") "$temp_golden_file"

  assert_test_pass
}
