#!/system/bin/sh
# Copyright (c) 2009-2010, Code Aurora Forum. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Code Aurora nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# /* < DTS2010073100955 xuhui 20100730 begin */ 
# the sleep path is not used on 7230
# /* < DTS2010101901100 xuhui 20101021 begin */ 
# add clock control for qtr8200
BLUETOOTH_CLOCK_PATH=/proc/bluetooth/clock/proto
# /* DTS2010101901100 xuhui 20101021 end > */
# /* DTS2010073100955 xuhui 20100730 end > */
LOG_TAG="qcom-bluetooth"
LOG_NAME="${0}:"

hciattach_pid=""

loge ()
{
  /system/bin/log -t $LOG_TAG -p e "$LOG_NAME $@"
}

logi ()
{
  /system/bin/log -t $LOG_TAG -p i "$LOG_NAME $@"
}

failed ()
{
  loge "$1: exit code $2"
  exit $2
}

start_hciattach ()
{
# /* < DTS2010073100955 xuhui 20100730 begin */ 
# sleep path mode is not used on 7230, if we ech 1 to a wrong path in /proc, the shell will be not sensitive to the signal send by init 
#  echo 1 > $BLUETOOTH_SLEEP_PATH
# /* DTS2010073100955 xuhui 20100730 end > */
  /system/bin/hciattach -n $BTS_DEVICE $BTS_TYPE $BTS_BAUD &
  hciattach_pid=$!
  logi "start_hciattach: pid = $hciattach_pid"
}

kill_hciattach ()
{
  logi "kill_hciattach: pid = $hciattach_pid"
  ## careful not to kill zero or null!
  kill -TERM $hciattach_pid
# /* < DTS2010073100955 xuhui 20100730 begin */ 
# sleep path mode is not used on 7230, if we ech 1 to a wrong path in /proc, the shell will be not sensitive to the signal send by init 
#  echo 0 > $BLUETOOTH_SLEEP_PATH
# /* DTS2010073100955 xuhui 20100730 end > */
  # this shell doesn't exit now -- wait returns for normal exit
}

# mimic hciattach options parsing -- maybe a waste of effort
USAGE="hciattach [-n] [-p] [-b] [-t timeout] [-s initial_speed] <tty> <type | id> [speed] [flow|noflow] [bdaddr]"

while getopts "blnpt:s:" f
do
  case $f in
  b | l | n | p)  opt_flags="$opt_flags -$f" ;;
  t)      timeout=$OPTARG;;
  s)      initial_speed=$OPTARG;;
  \?)     echo $USAGE; exit 1;;
  esac
done
shift $(($OPTIND-1))

# Note that "hci_qcomm_init -e" prints expressions to set the shell variables
# BTS_DEVICE, BTS_TYPE, BTS_BAUD, and BTS_ADDRESS.

eval $(/system/bin/hci_qcomm_init -2 -b 00:a0:c6:f2:51:9d -e && echo "exit_code_hci_qcomm_init=0" || echo "exit_code_hci_qcomm_init=1")

# /* < DTS2010101901100 xuhui 20101021 begin */ 
case $exit_code_hci_qcomm_init in
  0) logi "Bluetooth QSoC firmware download succeeded, $BTS_DEVICE $BTS_TYPE $BTS_BAUD $BTS_ADDRESS"
     echo 1 > $BLUETOOTH_CLOCK_PATH 
  ;;
  *) failed "Bluetooth QSoC firmware download failed" $exit_code_hci_qcomm_init;;
esac

# /* DTS2010101901100 xuhui 20101021 end > */
# init does SIGTERM on ctl.stop for service
trap "kill_hciattach" TERM INT

start_hciattach

wait $hciattach_pid

logi "Bluetooth stopped"

exit 0
