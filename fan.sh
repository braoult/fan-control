#!/usr/bin/env bash
#

CMD="${0##*/}"
sysdir="/sys/devices/platform/applesmc.768"

declare -a control_file label_file output_file
declare -al label

# get all fans information
fans_get_info() {
    local -i fan=1

    while [[ -f "$sysdir/fan${fan}_label" ]]; do
        label_file[$fan]="$sysdir/fan${fan}_label"
        control_file[$fan]="$sysdir/fan${fan}_manual"
        output_file[$fan]="$sysdir/fan${fan}_output"
        read -r label[$fan] < "${label_file[$fan]}"
        (( fan++ ))
    done
}

# fan_maybe_set_control()
# $1 is fan number (starting from 1)
# $2 is "0" for automatic, "1" for manual
fan_maybe_set_control() {
    local -i old fan="$1" value="$2"
    local -a mode=(auto manual)

    # get previous value
    read -r old < "${control_file[$fan]}"
    if [[ "$old" != "$value" ]]; then
        if echo "$value" > "${control_file[$fan]}"; then
            printf "fan mode set to %s\n" "${mode[$value]}"
        else
            printf "Try running command as root\n"
        fi
    fi
}

# fan_function() - set fan values (automatic/manual & speed)
# $1 is fan number (starting from 1)
# $2 is "auto" or percent to apply
fan_function() {
    local -i max min speed fan="$1"
    local percent="$2"

    # Get fan data from applesmc.768
    read -r max < "$sysdir/fan${fan}_max"
    read -r min < "$sysdir/fan${fan}_min"

    if [[ "$percent" = "auto" ]]; then
        # Set fan auto mode
        fan_maybe_set_control "$fan" 0
    else
        # Set fan manual mode
        fan_maybe_set_control "$fan" 1

        # Calculate the net value that will be given to the fans
        # formula : speed = min + [ (max - min) / 100 * percent ]
        speed=$(( min + (max - min) * percent / 100 ))

        # Write the final value to the applemc file
        if echo "$speed" > "${output_file[$fan]}"; then
            printf "fan set to %d rpm.\n" "$speed"
        else
            printf "Try running command as root\n"
        fi
    fi
}

usage() {
    printf "usage: %s [fan] [percent]\n" "$CMD"
    printf '  fan: "auto", "master", "exhaust", "hdd", "cpu" or "odd"\n'
    printf '  if fan is not "auto", percent is "auto" or a value between 0 and 100\n'
    exit 1
}

fans_get_info

if (($# == 0)); then
    printf "Available fans:\n"
    for fan in "${!label[@]}"; do
        printf "  %s\n" "${label[$fan]}"
    done
    exit 0
fi

# fan type and value
command="$1"
if [[ "$command" != "auto" ]]; then
    if (( $# == 2 )); then
        percent="$2"
    else
        usage
    fi
fi

case "$command" in
    ### AUTO CONTROL
    auto)
        for fan in "${!label[@]}"; do
            fan_maybe_set_control "$fan" 0
        done
        ;;

    ####  HDD/CPU/ODD/EXHAUST/MASTER CONTROL
    hdd|cpu|odd|exhaust|master)
        for fan in "${!label[@]}"; do
            if [[ "${label[$fan]}" = "$command" ]]; then
                fan_function "$fan" "$percent"
            fi
        done
        ;;

    *)
        printf 'unknown command %s\n' "$command"
        usage
esac
