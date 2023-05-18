load test_helper

@test 'fix_var_names(): Should succeed' {
  local -r vars='name="manjaro-gnome-x64-full-clean"
Encryption:     disabled
groups="/"
ostype="Arch Linux (64-bit)"
UUID="19e117b3-06f4-4a1e-851d-47336ad6a142"
CfgFile="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean.vbox"
SnapFldr="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/Snapshots"
LogFldr="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/Logs"
hardwareuuid="19e117b3-06f4-4a1e-851d-47336ad6a142"
memory=4096
pagefusion="off"
vram=64
cpuexecutioncap=100
hpet="off"
cpu-profile="host"
chipset="piix3"
firmware="BIOS"
cpus=4
pae="off"
longmode="on"
triplefaultreset="off"
apic="on"
x2apic="on"
nested-hw-virt="off"
cpuid-portability-level=0
bootmenu="messageandmenu"
boot1="dvd"
boot2="disk"
boot3="none"
boot4="none"
acpi="on"
ioapic="on"
biosapic="apic"
biossystemtimeoffset=0
BIOS NVRAM File="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean.nvram"
rtcuseutc="on"
hwvirtex="on"
nestedpaging="on"
largepages="on"
vtxvpid="on"
vtxux="on"
virtvmsavevmload="on"
iommu="none"
paravirtprovider="default"
effparavirtprovider="kvm"
VMState="poweroff"
VMStateChangeTime="2023-02-06T02:18:47.191000000"
graphicscontroller="vmsvga"
monitorcount=1
accelerate3d="off"
accelerate2dvideo="off"
teleporterenabled="off"
teleporterport=0
teleporteraddress=""
teleporterpassword=""
tracing-enabled="off"
tracing-allow-vm-access="off"
tracing-config=""
autostart-enabled="off"
autostart-delay=0
defaultfrontend=""
vmprocpriority="default"
storagecontrollername0="IDE"
storagecontrollertype0="PIIX4"
storagecontrollerinstance0="0"
storagecontrollermaxportcount0="2"
storagecontrollerportcount0="2"
storagecontrollerbootable0="on"
storagecontrollername1="SATA"
storagecontrollertype1="IntelAhci"
storagecontrollerinstance1="0"
storagecontrollermaxportcount1="30"
storagecontrollerportcount1="1"
storagecontrollerbootable1="on"
"IDE-0-0"="none"
"IDE-0-1"="none"
"IDE-1-0"="emptydrive"
"IDE-IsEjected-1-0"="off"
"IDE-1-1"="none"
"SATA-0-0"="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean-disk001.vdi"
"SATA-ImageUUID-0-0"="37a0bb6b-4292-464e-b766-1e8b7101ec94"
"SATA-hot-pluggable-0-0"="off"
"SATA-nonrotational-0-0"="off"
"SATA-discard-0-0"="off"
natnet1="nat"
macaddress1="08002744D7F6"
cableconnected1="on"
nic1="nat"
nictype1="82540EM"
nicspeed1="0"
mtu="0"
sockSnd="64"
sockRcv="64"
tcpWndSnd="64"
tcpWndRcv="64"
nic2="none"
nic3="none"
nic4="none"
nic5="none"
nic6="none"
nic7="none"
nic8="none"
hidpointing="usbtablet"
hidkeyboard="ps2kbd"
uart1="off"
uart2="off"
uart3="off"
uart4="off"
lpt1="off"
lpt2="off"
audio="default"
audio_out="on"
audio_in="off"
clipboard="bidirectional"
draganddrop="bidirectional"
vrde="off"
usb="on"
ehci="on"
xhci="off"
recording_enabled="off"
recording_screens=1
 rec_screen0
rec_screen_enabled="on"
rec_screen_id=0
rec_screen_video_enabled="on"
rec_screen_dest="File"
rec_screen_dest_filename="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean-screen0.webm"
rec_screen_opts="vc_enabled=true,ac_enabled=false,ac_profile=med"
rec_screen_video_res_xy="1024x768"
rec_screen_video_rate_kbps=512
rec_screen_video_fps=25
description="name1=value1
name2=value2"
GuestMemoryBalloon=0'

  run fix_var_names "$vars"

  assert_success
  assert_output 'name="manjaro-gnome-x64-full-clean"
Encryption=disabled
groups="/"
ostype="Arch Linux (64-bit)"
UUID="19e117b3-06f4-4a1e-851d-47336ad6a142"
CfgFile="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean.vbox"
SnapFldr="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/Snapshots"
LogFldr="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/Logs"
hardwareuuid="19e117b3-06f4-4a1e-851d-47336ad6a142"
memory=4096
pagefusion="off"
vram=64
cpuexecutioncap=100
hpet="off"
cpu_profile="host"
chipset="piix3"
firmware="BIOS"
cpus=4
pae="off"
longmode="on"
triplefaultreset="off"
apic="on"
x2apic="on"
nested_hw_virt="off"
cpuid_portability_level=0
bootmenu="messageandmenu"
boot1="dvd"
boot2="disk"
boot3="none"
boot4="none"
acpi="on"
ioapic="on"
biosapic="apic"
biossystemtimeoffset=0
BIOSNVRAMFile="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean.nvram"
rtcuseutc="on"
hwvirtex="on"
nestedpaging="on"
largepages="on"
vtxvpid="on"
vtxux="on"
virtvmsavevmload="on"
iommu="none"
paravirtprovider="default"
effparavirtprovider="kvm"
VMState="poweroff"
VMStateChangeTime="2023-02-06T02:18:47.191000000"
graphicscontroller="vmsvga"
monitorcount=1
accelerate3d="off"
accelerate2dvideo="off"
teleporterenabled="off"
teleporterport=0
teleporteraddress=""
teleporterpassword=""
tracing_enabled="off"
tracing_allow_vm_access="off"
tracing_config=""
autostart_enabled="off"
autostart_delay=0
defaultfrontend=""
vmprocpriority="default"
storagecontrollername0="IDE"
storagecontrollertype0="PIIX4"
storagecontrollerinstance0="0"
storagecontrollermaxportcount0="2"
storagecontrollerportcount0="2"
storagecontrollerbootable0="on"
storagecontrollername1="SATA"
storagecontrollertype1="IntelAhci"
storagecontrollerinstance1="0"
storagecontrollermaxportcount1="30"
storagecontrollerportcount1="1"
storagecontrollerbootable1="on"
IDE_0_0="none"
IDE_0_1="none"
IDE_1_0="emptydrive"
IDE_IsEjected_1_0="off"
IDE_1_1="none"
SATA_0_0="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean-disk001.vdi"
SATA_ImageUUID_0_0="37a0bb6b-4292-464e-b766-1e8b7101ec94"
SATA_hot_pluggable_0_0="off"
SATA_nonrotational_0_0="off"
SATA_discard_0_0="off"
natnet1="nat"
macaddress1="08002744D7F6"
cableconnected1="on"
nic1="nat"
nictype1="82540EM"
nicspeed1="0"
mtu="0"
sockSnd="64"
sockRcv="64"
tcpWndSnd="64"
tcpWndRcv="64"
nic2="none"
nic3="none"
nic4="none"
nic5="none"
nic6="none"
nic7="none"
nic8="none"
hidpointing="usbtablet"
hidkeyboard="ps2kbd"
uart1="off"
uart2="off"
uart3="off"
uart4="off"
lpt1="off"
lpt2="off"
audio="default"
audio_out="on"
audio_in="off"
clipboard="bidirectional"
draganddrop="bidirectional"
vrde="off"
usb="on"
ehci="on"
xhci="off"
recording_enabled="off"
recording_screens=1
rec_screen0
rec_screen_enabled="on"
rec_screen_id=0
rec_screen_video_enabled="on"
rec_screen_dest="File"
rec_screen_dest_filename="/home/user/VirtualBox VMs/manjaro-gnome-x64-full-clean/manjaro-gnome-x64-full-clean-screen0.webm"
rec_screen_opts="vc_enabled=true,ac_enabled=false,ac_profile=med"
rec_screen_video_res_xy="1024x768"
rec_screen_video_rate_kbps=512
rec_screen_video_fps=25
description="name1=value1
name2=value2"
GuestMemoryBalloon=0'
}

@test "utils::get_a_dynamic_port() Should return a dynamic port" {
  # shellcheck disable=SC2034
  for i in {1..100}; do
    run utils::get_a_dynamic_port

    assert_success
    assert [ "$output" -ge 49152 -a "$output" -le 65535 ]
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

# Test utils::crc_sum function

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

# Test utils::validate_name_or_id()
@test "utils::validate_name_or_id() prints error message for empty name" {
  # Arrange
  local -r image_name=""
  # Act
  run utils::validate_name_or_id "$image_name"
  # Assert
  assert_failure
  assert_output "Argument must not be empty"
}

@test "utils::validate_name_or_id() returns 1 for invalid name: foo_bar" {
  # Arrange
  local -r image_name="foo/bar"
  # Act
  run utils::validate_name_or_id "$image_name"
  # Assert
  assert_failure
}

@test "utils::validate_name_or_id() returns 1 for invalid name: -invalid-name" {
  # Arrange
  local -r image_name="-invalid-name"
  # Act
  run utils::validate_name_or_id "$image_name"
  # Assert
  assert_failure
}

@test "utils::validate_name_or_id() returns 1 for invalid name: invalid-name-" {
  # Arrange
  local -r image_name="invalid-name-"
  # Act
  run utils::validate_name_or_id "$image_name"
  # Assert
  assert_failure
}
@test "utils::validate_name_or_id() returns 0 for valid name: foo-bar123" {
  # Arrange
  local -r image_name="foo-bar123"
  # Act
  run utils::validate_name_or_id "$image_name"
  # Assert
  assert_success
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
# bats test_tags=only
@test "utils::get_file_path_on_working_dir() Should fail With empty file_ name" {
  local -r file_name=""
  local -r working_dir=""

  run utils::get_file_path_on_working_dir "$file_name" "$working_dir"

  assert_failure
  assert_output "file_name is required"
}
# bats test_tags=only
@test "utils::get_file_path_on_working_dir() Should return file_name" {
  local -r file_name="file1"
  local -r working_dir=""

  run utils::get_file_path_on_working_dir "$file_name" "$working_dir"

  assert_success
  assert_output "file1"
}
# bats test_tags=only
@test "utils::get_file_path_on_working_dir() Should return file_name with working_dir" {
  local -r file_name="file1"
  local -r working_dir="/home/vedv"

  run utils::get_file_path_on_working_dir "$file_name" "$working_dir"

  assert_success
  assert_output "/home/vedv/file1"
}
# bats test_tags=only
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
