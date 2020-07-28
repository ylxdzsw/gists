#!/usr/bin/zsh

# usage: ./arknights.zsh 3m 7
# where 3m is the time for one battle (default: 2m).
#       7 is number of battles in a row (default: 1).

repeat ${2:-1} {
    adb shell input tap 1700 950
    sleep 3
    adb shell input tap 1600 850
    sleep ${1:-2m}
    echo finished
    adb shell input tap 1600 500
    sleep 4
}

notify-send Arknights 'all done'