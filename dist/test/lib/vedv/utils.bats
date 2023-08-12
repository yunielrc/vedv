# shellcheck disable=SC2016
load test_helper

setup() {
  utils::constructor "$TEST_TMP_DIR" \
    'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36'
  export __VEDV_UTILS_TMP_DIR
}

@test "utils::get_a_dynamic_port() Should return a dynamic port" {
  local _min _man
  read -r _min _max </proc/sys/net/ipv4/ip_local_port_range
  readonly _min _max
  # shellcheck disable=SC2034
  for i in {1..100}; do
    run utils::get_a_dynamic_port

    assert_success
    assert [ "$output" -ge "$_min" -a "$output" -le "$_max" ]
  done
}

@test "utils::string::trim() Should handles an empty string correctly" {
  local text=""

  run utils::string::trim <<<"$text"

  assert_success
  assert_output ''

  run utils::string::trim "$text"

  assert_success
  assert_output ''
}

@test "utils::string::trim() Should Trims the beginning and end of a string" {
  local -r text="  Hello World!  "

  run utils::string::trim <<<"$text"

  assert_success
  assert_output "Hello World!"

  run utils::string::trim "$text"

  assert_success
  assert_output "Hello World!"
}

@test "utils::string::trim() Should Trims the leading and trailing spaces for multiple lines" {
  local text="  Hello   Hello



    World!  "

  run utils::string::trim <<<"$text"

  assert_success
  assert_output "Hello   Hello
World!"

  run utils::string::trim "$text"

  assert_success
  assert_output "Hello   Hello
World!"
}

@test "utils::string::trim() Should not remove leading or trailing spaces within a string" {
  local text=",Hello World!"

  run utils::string::trim <<<"$text"

  assert_success
  assert_output ",Hello World!"
}

@test "utils::valid_ip() Should fail With invalid IP" {
  run utils::valid_ip "not an IP"
  assert_failure
}

@test "utils::valid_ip() Should fail With IP value greater than 255" {
  run utils::valid_ip "256.255.255.255"
  assert_failure
}

@test "utils::valid_ip() Should fail With IP value less than 0" {
  run utils::valid_ip "-1.0.0.0"
  assert_failure
}

@test "utils::valid_ip() Should success With IP with value between 0 and 255" {
  run utils::valid_ip "100.100.100.100"
  assert_success
}

@test "utils::valid_ip() Should success With valid IP" {
  run utils::valid_ip "192.168.0.1"
  assert_success
}

# Tests for utils::crc_sum()

@test "utils::crc_file_sum(), Should fail When the file does not exist" {
  run utils::crc_file_sum '/no_file/exists'

  assert_failure
  assert_output --partial 'No such file or directory'
}

@test "utils::crc_file_sum(), Should compute crc sum from a directory" {
  local -r dir='dist/test/lib/vedv/fixtures/utils/directory'

  run utils::crc_file_sum "$dir"

  assert_success
  assert_output '2904904567'
}

@test "utils::crc_sum(), Should compute the correct checksum for input from stdin" {
  run_function() { echo "hello world" | utils::crc_sum; }
  run run_function

  assert_success
  assert_output "3733384285"
}

@test "utils::crc_sum(), Should success When a file argument is provided" {
  run utils::crc_sum /dev/null
  assert_success
  assert_output '4294967295'
}

# Test utils::get_arg_from_string function
@test "utils::get_arg_from_string(), Should returns an error if the args argument is empty" {
  run utils::get_arg_from_string "" 1
  assert_failure
  assert_output "Argument 'args' must not be empty"
}

@test "utils::get_arg_from_string(), Should returns an error if the arg_pos argument is empty" {
  run utils::get_arg_from_string "foo bar baz" ""
  assert_failure
  assert_output "Argument 'arg_pos' must not be empty"
}

@test "utils::get_arg_from_string(), Should returns an error if the argument position is out of range" {
  run utils::get_arg_from_string "foo bar baz" 4
  assert_failure
  assert_output "Argument 'arg_pos' must be between 1 and 3"
}

@test "utils::get_arg_from_string(), Should returns the first argument from a string" {
  run utils::get_arg_from_string "foo bar baz" 1
  assert_success
  assert_output "foo"
}

@test "utils::get_arg_from_string(), Should returns the second argument from a string" {
  run utils::get_arg_from_string "foo 'bar bar' baz" 2
  assert_success
  assert_output "bar bar"
}

@test "utils::get_arg_from_string(), Should returns the third argument from a string" {
  run utils::get_arg_from_string "foo bar baz" 3
  assert_success
  assert_output "baz"
}

@test "utils::get_arg_from_string(), Should returns the argument 4 '/home/vedv/' from a string" {
  run utils::get_arg_from_string "2 COPY homefs/* /home/vedv/" 4
  assert_success
  assert_output "/home/vedv/"
}

@test "utils::get_arg_from_string(), Should returns the argument 3 'homefs/*' from a string" {
  run utils::get_arg_from_string "2 COPY homefs/* /home/vedv/" 3
  assert_success
  assert_output "homefs/*"
}

@test "utils::get_arg_from_string(), Should returns the argument 2 'RUN' from a string uname..." {
  skip # This doesn't work with the current implementation
  run utils::get_arg_from_string "3  RUN uname -r > uname-r.txt" 2
  assert_success
  assert_output "RUN"
}

# Test utils::get_first_invalid_positions_between_two_arrays()
calc_item_id_from_array_a() { echo "$1"; }
calc_item_id_from_array_b() { echo "$1"; }

@test "utils::get_first_invalid_positions_between_two_arrays() returns -1|-1 when both arrays are empty" {
  local -r arr_a=()
  local -r arr_b=()

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "-1|-1"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns -1|-1 when both arrays have same length and same ids" {

  local -r arr_a=("apple" "banana" "cherry")
  local -r arr_b=("apple" "banana" "cherry")

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "-1|-1"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns first invalid positions when both arrays have same length but different ids at some point" {

  local -r arr_a=("apple" "banana" "cherry")
  local -r arr_b=("apple" "baboon" "dog")

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "1|1"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns first invalid positions when array A is longer than array B and they have same ids until array B ends" {

  local -r arr_a=("apple" "banana" "cherry")
  local -r arr_b=("apple")

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "1|-1"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns first invalid positions when array B is longer than array A and they have same ids until array A ends" {

  local -r arr_a=("apple")
  local -r arr_b=("apple" "banana" "cherry")

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "-1|1"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns first invalid positions when array B is empty" {

  local -r arr_a=("apple" "banana" "cherry")
  local -r arr_b=()

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "0|-1"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns first invalid positions when array A is empty" {

  local -r arr_a=()
  local -r arr_b=("apple" "banana" "cherry")

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "-1|0"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns first invalid positions when array A is longer than array B and they have one different id at the end" {

  local -r arr_a=("apple" "banana" "cherry")
  local -r arr_b=("apple" "baboon")

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "1|1"
}

@test "utils::get_first_invalid_positions_between_two_arrays() returns first invalid positions when array B is longer than array A and they have one different id at the end" {
  # shellcheck disable=SC2034
  local -r arr_a=("apple" "baboon")
  # shellcheck disable=SC2034
  local -r arr_b=("apple" "banana" "cherry")

  run utils::get_first_invalid_positions_between_two_arrays arr_a calc_item_id_from_array_a arr_b calc_item_id_from_array_b

  assert_success
  assert_output "1|1"
}

# Tests for utils::array::to_string()

@test "utils::array::to_string() Should succeed With empty array" {
  # shellcheck disable=SC2034
  local -r arr=()

  run utils::array::to_string arr

  assert_success
  assert_output "()"

  run arr2str arr

  assert_success
  assert_output "()"
}

# Test for utils::str_encode()

@test "utils::str_encode() Should succeed With empty string" {
  local -r str=""

  run utils::str_encode "$str"

  assert_success
  assert_output ""
}

@test "utils::str_encode() Should succeed With string without special characters" {
  local -r str="foo"

  run utils::str_encode "$str"

  assert_success
  assert_output "foo"
}

@test "utils::str_encode() Should succeed With string with special characters" {
  local -r str="uname -r >uname-r.txt && echo 'Hello World' >hello.txt"

  run utils::str_encode "$str"

  assert_success
  assert_output "uname -r >uname-r.txt && echo 3c5d99d4c5Hello World3c5d99d4c5 >hello.txt"
}

@test "utils::str_encode() Should succeed With string with special characters 2" {
  local -r str='uname -r >uname-r.txt && echo "Hello World" >hello.txt'

  run utils::str_encode "$str"

  assert_success
  assert_output "uname -r >uname-r.txt && echo f7ce31e217Hello Worldf7ce31e217 >hello.txt"
}

# Test for utils::str_decode()

@test "utils::str_decode() Should succeed With empty string" {
  local -r str=""

  run utils::str_decode "$str"

  assert_success
  assert_output ""
}

@test "utils::str_decode() Should succeed With string without special characters" {
  local -r str="foo"

  run utils::str_decode "$str"

  assert_success
  assert_output "foo"
}

@test "utils::str_decode() Should succeed With string with special characters" {
  local -r str="uname -r >uname-r.txt && echo 3c5d99d4c5Hello World3c5d99d4c5 >hello.txt"

  run utils::str_decode "$str"

  assert_success
  assert_output "uname -r >uname-r.txt && echo 'Hello World' >hello.txt"
}

@test "utils::str_decode() Should succeed With string with special characters 2" {
  local -r str="uname -r >uname-r.txt && echo 3c5d99d4c5Hello World3c5d99d4c5 >hello.txt"

  run utils::str_decode "$str"

  assert_success
  assert_output "uname -r >uname-r.txt && echo 'Hello World' >hello.txt"
}

# Tests for utils::get_file_path_on_working_dir()

@test "utils::get_file_path_on_working_dir() Should fail With empty file_ name" {
  local -r file_name=""
  local -r working_dir=""

  run utils::get_file_path_on_working_dir "$file_name" "$working_dir"

  assert_failure
  assert_output "file_name is required"
}

@test "utils::get_file_path_on_working_dir() Should return file_name" {
  local -r file_name="file1"
  local -r working_dir=""

  run utils::get_file_path_on_working_dir "$file_name" "$working_dir"

  assert_success
  assert_output "file1"
}

@test "utils::get_file_path_on_working_dir() Should return file_name with working_dir" {
  local -r file_name="file1"
  local -r working_dir="/home/vedv"

  run utils::get_file_path_on_working_dir "$file_name" "$working_dir"

  assert_success
  assert_output "/home/vedv/file1"
}

@test "utils::get_file_path_on_working_dir() Should return file_name 1" {
  local -r file_name="/file1"
  local -r working_dir="/home/vedv"

  run utils::get_file_path_on_working_dir "$file_name" "$working_dir"

  assert_success
  assert_output "/file1"
}

# Tests for utils::str_escape_quotes()
@test "utils::str_escape_quotes() Should succeed With empty string" {
  local -r str=""

  run utils::str_escape_quotes "$str"

  assert_success
  assert_output ""
}

@test "utils::str_escape_quotes() Should succeed With string without special characters" {
  local -r str="foo"

  run utils::str_escape_quotes "$str"

  assert_success
  assert_output "foo"
}

@test "utils::str_escape_quotes() Should succeed With string with special characters" {
  local -r str=$'uname -r >"uname-r.txt" && echo \'Hello World\' >hello.txt'

  run utils::str_escape_quotes "$str"

  assert_success
  assert_output "uname -r >\\\"uname-r.txt\\\" && echo \'Hello World\' >hello.txt"
}

# Tests for utils::str_remove_quotes()
@test "utils::str_remove_quotes() Should succeed With empty string" {
  local -r str=""

  run utils::str_remove_quotes "$str"

  assert_success
  assert_output ""
}

@test "utils::str_remove_quotes() Should succeed With string without quotes" {
  local -r str="foo"

  run utils::str_remove_quotes "$str"

  assert_success
  assert_output "foo"
}

@test "utils::str_remove_quotes() Should succeed With string with quotes" {
  local -r str=$'uname -r >"uname-r.txt" && echo \'Hello World\' >hello.txt'

  run utils::str_remove_quotes "$str"

  assert_success
  assert_output "uname -r >uname-r.txt && echo Hello World >hello.txt"
}

# Tests for utils::str_encode_vars()
@test "utils::str_encode_vars() Should succeed With empty string" {
  local -r str=""

  run utils::str_encode_vars "$str"

  assert_success
  assert_output ""
}

@test "utils::str_encode_vars() Should succeed With string without special characters" {
  local -r str="foo"

  run utils::str_encode_vars "$str"

  assert_success
  assert_output "foo"
}

@test "utils::str_encode_vars() Should succeed With string with special characters" {
  local -r str='2 RUN echo $NAME
3 COPY . \$HOME
4 RUN ls -l ${HOME}'

  run utils::str_encode_vars "$str"

  assert_success
  assert_output '2 RUN echo $var_9f57a558b3_NAME
3 COPY . escvar_fc064fcc7e_HOME
4 RUN ls -l ${var_9f57a558b3_HOME}'
}

# Tests for utils::str_decode_vars()
@test "utils::str_decode_vars() Should succeed With empty string" {
  local -r str=""

  run utils::str_decode_vars "$str"

  assert_success
  assert_output ""
}

@test "utils::str_decode_vars() Should succeed With string without special characters" {
  local -r str="foo"

  run utils::str_decode_vars "$str"

  assert_success
  assert_output "foo"
}

@test "utils::str_decode_vars() Should succeed With string with special characters" {
  local -r str='2 RUN echo $var_9f57a558b3_NAME
3 COPY . escvar_fc064fcc7e_HOME
4 RUN ls -l ${var_9f57a558b3_HOME}'

  run utils::str_decode_vars "$str"

  assert_success
  assert_output '2 RUN echo $NAME
3 COPY . \$HOME
4 RUN ls -l ${HOME}'
}

# Tests for utils::sha256sum_check()

@test "utils::sha256sum_check() Should fail With empty file_path" {
  local -r checksum_file=""

  run utils::sha256sum_check "$checksum_file"

  assert_failure
  assert_output "checksum_file is required"
}

@test "utils::sha256sum_check() Should fail If checksum_file does not exist" {
  local -r checksum_file="sdjfkljewlijflsa.sha256sum"

  run utils::sha256sum_check "$checksum_file"

  assert_failure
  assert_output "checksum file doesn't exist"
}

@test "utils::sha256sum_check() Should fail If checksum fail" {
  local -r checksum_file="$(mktemp)"

  run utils::sha256sum_check "$checksum_file"

  assert_failure
  assert_output "checksum doesn't match"
}

@test "utils::sha256sum_check() Should succeed If checksum success" {
  local -r checksum_file="${TEST_OVA_FILE}.sha256sum"

  run utils::sha256sum_check "$checksum_file"

  assert_success
  assert_output ""
}

# Tests for utils::is_url()

@test "utils::is_url() Should fail With empty url" {
  local -r url=""

  run utils::is_url "$url"

  assert_failure
  assert_output ""
}

@test "utils::is_url() Should fail With invalid url" {
  local -r url="foo"

  run utils::is_url "$url"

  assert_failure
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url" {
  local -r url="https://www.google.com"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with port" {
  local -r url="https://www.google.com:8080"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with path" {
  local -r url="https://www.google.com/foo/bar"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with query" {
  local -r url="https://www.google.com?foo=bar"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with fragment" {
  local -r url="https://www.google.com#foo"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with user" {
  local -r url="https://user@localhost"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with user and password" {
  local -r url="https://user:password@localhost"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with user and password and port" {
  local -r url="https://user:password@localhost:8080"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with user and password and port and path" {
  local -r url="https://user:password@localhost:8080/foo/bar"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with user and password and port and path and query" {
  local -r url="https://user:password@localhost:8080/foo/bar?foo=bar"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should succeed With valid url with user and password and port and path and query and fragment" {
  local -r url="https://user:password@localhost:8080/foo/bar?foo=bar#foo"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

@test "utils::is_url() Should fail With valid url with user and password and port and path and query and fragment and invalid scheme" {
  local -r url="foo://user:password@localhost:8080/foo/bar?foo=bar#foo"

  run utils::is_url "$url"

  assert_failure
  assert_output ""
}

@test "utils::is_url() Should succeed" {
  local -r url="https://www.google.com/search?q=regular+expresion+to+validate+an+url+in+BASH&biw=1463&bih=760&sxsrf=APwXEdd1cZuaNKYRftKufCdN9QgG6QeXwQ%3A1686364282081&ei=euCDZNPMBLyGwbkPm8u-2AM&ved=0ahUKEwjT8fq_1Lf_AhU8QzABHZulDzsQ4dUDCBE&uact=5&oq=regular+expresion+to+validate+an+url+in+BASH&gs_lcp=Cgxnd3Mtd2lzIHCCEQoAEQCjIHCCEQoAEQCjoECCMQJzoHCCMQigUQJzoHCC4QigUQJzoHCAAQigUQQzoICAAQigUQkQI6CwgAEIAEELEDEIMBOggILhCAgUQsQMQgwEQQzoICAAQgAQQsQM6BQgAEIAEOgoIABCAgjELACECc6CAgAEAgQBxAeOggIABAFEB4QDToICAAQigUQhgM6BQgAEKIEOgQIIRAKOgcIIRCrAhAKOgoIIRAWEB4QHRAKSgQIQRgAUABYjGpg-m1oAHABeAGAAbQBiAHcIJIBBTI5LjE1mAEAoAEBwAEB&sclient=gws-wiz-serp"

  run utils::is_url "$url"

  assert_success
  assert_output ""
}

# Tests for utils::mktmp_dir()

@test "utils::mktmp_dir() Should succeed" {

  local dir="$(utils::mktmp_dir)"

  assert [ -d "$dir" ]
}

# Tests for utils::download_file()

@test "utils::download_file() Should fail With empty url" {
  local -r url=""

  run utils::download_file "$url" "$TEST_OVA_FILE"

  assert_failure
  assert_output "url is required"
}

@test "utils::download_file() Should fail With invalid url" {
  local -r url="https:www.google.com"

  run utils::download_file "$url" ""

  assert_failure
  assert_output "url is not valid"
}

@test "utils::download_file() Should fail With empty destination" {
  local -r url="https://www.google.com"

  run utils::download_file "$url" ""

  assert_failure
  assert_output "file is required"
}

@test "utils::download_file() Should fail If download fails" {
  local -r url="http://f2c2b9201b6edf4d7e5ef219c540a744.get"
  local -r file="$(mktemp)"

  run utils::download_file "$url" "$file"

  assert_failure
  assert_output "error downloading file"
}

@test "utils::download_file() Should succeed" {
  local -r url="$TEST_OVA_CHECKSUM"
  local -r file="$(mktemp)"

  run utils::download_file "$url" "$file"

  assert_success
  assert_output ""
}

# Tests for utils::validate_sha256sum_format()
# bats test_tags=only
@test "utils::validate_sha256sum_format() Should fail With empty sha256sum" {
  local -r sha256sum=""

  run utils::validate_sha256sum_format "$sha256sum"

  assert_failure
  assert_output "checksum_file is required"
}
# bats test_tags=only
@test "utils::validate_sha256sum_format() Should if file does not exist" {
  local -r sha256sum="/tmp/f18c7b0d63"

  run utils::validate_sha256sum_format "$sha256sum"

  assert_failure
  assert_output "checksum file doesn't exist"
}
# bats test_tags=only
@test "utils::validate_sha256sum_format() Should checksum format is invalid" {
  local -r sha256sum="$(mktemp)"
  echo "f18c7b0d63" >"$sha256sum"

  run utils::validate_sha256sum_format "$sha256sum"

  assert_failure
  assert_output ""
}
# bats test_tags=only
@test "utils::validate_sha256sum_format() Should succeed" {
  local -r sha256sum="$(mktemp)"
  echo "83a0bbec167c280145ffafc6df65ec5fd74dec864c18535d71abfa3bb64c2663  /tmp/ova.ova" >"$sha256sum"

  run utils::validate_sha256sum_format "$sha256sum"

  assert_success
  assert_output ""
}

# Tests for utils::random_number()
@test "utils::random_number() Should succeed" {
  local -r rstring="$(utils::random_number)"

  assert [ -n "$rstring" ]
}

# Tests for utils::escape_for_bregex()
@test "utils::escape_for_bregex() Should succeed" {
  local -r str=".foo."

  run utils::escape_for_bregex "$str"

  assert_success
  assert_output "\.foo\."
}
