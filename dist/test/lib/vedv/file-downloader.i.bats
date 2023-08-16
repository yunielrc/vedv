# shellcheck disable=SC2016,SC2317
load test_helper

setup() {
  file_downloader::constructor \
    'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36'
  export __VEDV_FILE_DOWNLOADER_USER_AGENT
  readonly DOWNLOADED_FILE="$(mktemp)"
}

teardown() {
  if [[ -f "$DOWNLOADED_FILE" ]]; then
    rm -f "$DOWNLOADED_FILE"
  fi
}

# Tests for file_downloader::__validate_args()
@test "file_downloader::__validate_args() Should fail With empty url" {
  local -r url=""
  local -r file=""

  run file_downloader::__validate_args "$url" "$file"

  assert_failure
  assert_output "url is required"
}

@test "file_downloader::__validate_args() Should fail With invalid url" {
  local -r url="https:www.google.com"
  local -r file=""

  run file_downloader::__validate_args "$url" "$file"

  assert_failure
  assert_output "url is not valid"
}

@test "file_downloader::__validate_args() Should fail With empty destination" {
  local -r url="https://www.google.com"
  local -r file=""

  run file_downloader::__validate_args "$url" "$file"

  assert_failure
  assert_output "file is required"
}

@test "file_downloader::__validate_args() Should succeed" {
  local -r url="https://www.google.com"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::__validate_args "$url" "$file"

  assert_success
  assert_output ""
}

# Tests for file_downloader::http_download()
@test "file_downloader::http_download() Should fail if validate_args fails" {
  local -r url="http://example.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::__validate_args() {
    assert_equal "$*" "${url} ${file}"
    return 1
  }

  run file_downloader::http_download "$url" "$file"

  assert_failure
  assert_output ""
}

@test "file_downloader::http_download() Should fail If download fails" {
  local -r url="http://f2c2b9201b6edf4d7e5ef219c540a744.get"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::http_download "$url" "$file"

  assert_failure
  assert_output "error downloading file from ${url}"
}

@test "file_downloader::http_download() Should succeed" {
  local -r url="$TEST_OVA_INVARIABLE_CHECKSUM_URL"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::http_download "$url" "$file"

  assert_success
  assert_output ""

  assert [ -f "$file" ]

  run cat "$file"

  assert_success
  assert_output "6c9f85acaffe1335ecc9197808ffe8764ce3167ed86480b9b08372987aab828d  alpine-linux-invariable.ova"
}

# Tests for file_downloader::onedrive_embed_download()
@test "file_downloader::onedrive_embed_download() Should fail if validate_args fails" {
  local -r url="http://example.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::__validate_args() {
    assert_equal "$*" "${url} ${file}"
    return 1
  }

  run file_downloader::onedrive_embed_download "$url" "$file"

  assert_failure
  assert_output ""
}

@test "file_downloader::onedrive_embed_download() Should fail If download fails" {
  local -r url="http://f2c2b9201b6edf4d7e5ef219c540a744.get"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::onedrive_embed_download "$url" "$file"

  assert_failure
  assert_output "error downloading file from ${url}"
}

@test "file_downloader::onedrive_embed_download() Should succeed" {
  local -r url='https://onedrive.live.com/embed?resid=DBA0B75F07574EAA%21274&authkey=!AH7DMJWc2r5Y2IY'
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::onedrive_embed_download "$url" "$file"

  assert_success
  assert_output ""

  assert [ -f "$file" ]

  run cat "$file"

  assert_success
  assert_output "6c9f85acaffe1335ecc9197808ffe8764ce3167ed86480b9b08372987aab828d  alpine-linux-invariable.ova"
}

# Tests for file_downloader::gdrive_big_download()
@test "file_downloader::gdrive_big_download() Should fail if validate_args fails" {
  local -r url="http://example.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::__validate_args() {
    assert_equal "$*" "${url} ${file}"
    return 1
  }

  run file_downloader::gdrive_big_download "$url" "$file"

  assert_failure
  assert_output ""
}

@test "file_downloader::gdrive_big_download() Should fail If getting file_id fails" {
  local -r url="http://f2c2b92.get"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::gdrive_big_download "$url" "$file"

  assert_failure
  assert_output "error getting file id from ${url}"
}

@test "file_downloader::gdrive_big_download() Should fail If mktemp fails" {
  local -r url="$TEST_GDRIVE_FILE_101MB_URL"
  local -r file="$DOWNLOADED_FILE"

  __run_wrapper() {
    mktemp() {
      return 1
    }
    file_downloader::gdrive_big_download "$@"
  }

  run __run_wrapper "$url" "$file"

  assert_failure
  assert_output "error creating temp file"
}

@test "file_downloader::gdrive_big_download() Should fail If getting confirm fails" {
  local -r url="$TEST_GDRIVE_FILE_101MB_URL"
  local -r file="$DOWNLOADED_FILE"

  wget() {
    if [[ "$*" == *'uc?export=download'* ]]; then
      return 1
    fi
    command wget "$@"
  }

  run file_downloader::gdrive_big_download "$url" "$file"

  assert_failure
  assert_output "error getting confirmation from ${url}"
}

@test "file_downloader::gdrive_big_download() Should fail If download fails" {
  local -r url="$TEST_GDRIVE_FILE_101MB_URL"
  local -r file="$DOWNLOADED_FILE"

  local -r wget_calls_file="$(mktemp)"
  echo 0 >"$wget_calls_file"

  wget() {
    if [[ "$*" == *'uc?export=download'* ]]; then
      local -i wget_calls="$(<"$wget_calls_file")"
      echo "$((++wget_calls))" >"$wget_calls_file"

      if [[ "$wget_calls" == 2 ]]; then
        return 1
      fi
    fi
    command wget "$@"
  }

  run file_downloader::gdrive_big_download "$url" "$file"

  assert_failure
  assert_output "error downloading file from ${url}"
}

@test "file_downloader::gdrive_big_download() Should succeed" {
  local -r url="$TEST_GDRIVE_FILE_101MB_URL"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::gdrive_big_download "$url" "$file"

  assert_success
  assert_output ""

  assert [ -f "$file" ]

  run du -h "$file"

  assert_success
  assert_output --partial "101M"
}

# Tests for file_downloader::gdrive_small_download()
@test "file_downloader::gdrive_small_download() Should fail if validate_args fails" {
  local -r url="http://example.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::__validate_args() {
    assert_equal "$*" "${url} ${file}"
    return 1
  }

  run file_downloader::gdrive_small_download "$url" "$file"

  assert_failure
  assert_output ""
}

@test "file_downloader::gdrive_small_download() Should fail If getting file_id fails" {
  local -r url="http://f2c2b92.get"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::gdrive_small_download "$url" "$file"

  assert_failure
  assert_output "error getting file id from ${url}"
}

@test "file_downloader::gdrive_small_download() Should fail If download fails" {
  local -r url="$TEST_GDRIVE_FILE_1MB_URL"
  local -r file="$DOWNLOADED_FILE"

  wget() {
    if [[ "$*" == *'uc?export=download'* ]]; then
      return 1
    fi
    command wget "$@"
  }

  run file_downloader::gdrive_small_download "$url" "$file"

  assert_failure
  assert_output "error downloading file from ${url}"
}

@test "file_downloader::gdrive_small_download() Should succeed" {
  local -r url="$TEST_GDRIVE_FILE_1MB_URL"
  local -r file="$DOWNLOADED_FILE"

  run file_downloader::gdrive_small_download "$url" "$file"

  assert_success
  assert_output ""

  assert [ -f "$file" ]

  run du -h "$file"

  assert_success
  assert_output --partial "1.0M"
}

# Tests for file_downloader::is_address()
@test "file_downloader::is_address() Should fail With empty address" {
  local -r address=""

  run file_downloader::is_address "$address"

  assert_failure
  assert_output "address is required"
}

@test "file_downloader::is_address() Should Output false With invalid address" {
  local -r address="asdfasdf"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "false"
}

@test "file_downloader::is_address() Should Output true With http address" {
  local -r address="http://example.com/file.txt"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "true"
}

@test "file_downloader::is_address() Should Output true With https address" {
  local -r address="https://example.com/file.txt"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "true"
}

@test "file_downloader::is_address() Should Output true With http= address" {
  local -r address="http=http://example.com/file.txt"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "true"
}

@test "file_downloader::is_address() Should Output true With https= address" {
  local -r address="https=https://example.com/file.txt"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "true"
}

@test "file_downloader::is_address() Should Output true With gdrive-big= address" {
  local -r address="gdrive-big=https://drive.google.com/file/d/1IHLPhNZ4WCc2X9z6qSccmXp0hBeGKO16/view?usp=drive_link"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "true"
}

@test "file_downloader::is_address() Should Output true With gdrive-small= address" {
  local -r address="gdrive-small=https://drive.google.com/file/d/1LIpOrrv4dPMtkoD7bPqQxgP5inRJrpRh/view?usp=drive_link"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "true"
}

@test "file_downloader::is_address() Should Output true With onedrive= address" {
  local -r address="onedrive=https://onedrive.live.com/embed?resid=DBA0B75F07574EAA%21272&authkey=!AP8U5cI4V7DusSg"

  run file_downloader::is_address "$address"

  assert_success
  assert_output "true"
}

# Tests for file_downloader::any_download()
@test "file_downloader::any_download() Should fail With empty address" {
  local -r address=""
  local -r file=""

  run file_downloader::any_download "$address" "$file"

  assert_failure
  assert_output "address is required"
}

@test "file_downloader::any_download() Should fail With invalid address" {
  local -r address="asdfasdf"
  local -r file=""

  run file_downloader::any_download "$address" "$file"

  assert_failure
  assert_output "address is not valid"
}

@test "file_downloader::any_download() Should fail With empty destination" {
  local -r address="https://www.google.com"
  local -r file=""

  run file_downloader::any_download "$address" "$file"

  assert_failure
  assert_output "file is required"
}

@test "file_downloader::any_download() Should call http_download If address is an url" {
  local -r address="https://www.google.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::http_download() {
    assert_equal "$*" "${address} ${file}"
  }

  run file_downloader::any_download "$address" "$file"

  assert_success
  assert_output ""
}

@test "file_downloader::any_download() Should call gdrive_big_download" {
  local -r address="gdrive-big=https://drive.google.com/file/d/1IHLPhNZ4WCc2X9z6qSccmXp0hBeGKO16/view?usp=drive_link"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::gdrive_big_download() {
    assert_equal "$*" "${address#*=} ${file}"
  }
  file_downloader::gdrive_small_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::onedrive_embed_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::magnet_link_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::http_download() {
    assert_equal "$*" "INVALID_CALL"
  }

  run file_downloader::any_download "$address" "$file"

  assert_success
  assert_output ""
}

@test "file_downloader::any_download() Should call gdrive_small_download" {
  local -r address="gdrive-small=https://drive.google.com/file/d/1LIpOrrv4dPMtkoD7bPqQxgP5inRJrpRh/view?usp=drive_link"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::gdrive_big_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::gdrive_small_download() {
    assert_equal "$*" "${address#*=} ${file}"
  }
  file_downloader::onedrive_embed_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::magnet_link_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::http_download() {
    assert_equal "$*" "INVALID_CALL"
  }

  run file_downloader::any_download "$address" "$file"

  assert_success
  assert_output ""
}

@test "file_downloader::any_download() Should call onedrive_embed_download" {
  local -r address="onedrive=https://onedrive.live.com/embed?resid=DBA0B75F07574EAA%21272&authkey=!AP8U5cI4V7DusSg"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::gdrive_big_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::gdrive_small_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::onedrive_embed_download() {
    assert_equal "$*" "${address#*=} ${file}"
  }
  file_downloader::magnet_link_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::http_download() {
    assert_equal "$*" "INVALID_CALL"
  }

  run file_downloader::any_download "$address" "$file"

  assert_success
  assert_output ""
}

@test "file_downloader::any_download() Should call magnet_link_download" {
  local -r address="magnet=http://example.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::gdrive_big_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::gdrive_small_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::onedrive_embed_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::magnet_link_download() {
    assert_equal "$*" "${address#*=} ${file}"
  }
  file_downloader::http_download() {
    assert_equal "$*" "INVALID_CALL"
  }

  run file_downloader::any_download "$address" "$file"

  assert_success
  assert_output ""
}

@test "file_downloader::any_download() Should call http_download" {
  local -r address="http=http://example.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::gdrive_big_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::gdrive_small_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::onedrive_embed_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::magnet_link_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::http_download() {
    assert_equal "$*" "${address#*=} ${file}"
  }

  run file_downloader::any_download "$address" "$file"

  assert_success
  assert_output ""
}

@test "file_downloader::any_download() Should call http_download 2" {
  local -r address="https=http://example.com"
  local -r file="$DOWNLOADED_FILE"

  file_downloader::gdrive_big_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::gdrive_small_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::onedrive_embed_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::magnet_link_download() {
    assert_equal "$*" "INVALID_CALL"
  }
  file_downloader::http_download() {
    assert_equal "$*" "${address#*=} ${file}"
  }

  run file_downloader::any_download "$address" "$file"

  assert_success
  assert_output ""
}
