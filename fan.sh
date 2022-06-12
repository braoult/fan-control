#!/usr/bin/env bash
#
# fan.sh - Max Linux fan operations
#
# (C) Juan Pablo Carosi Warburg, 2020-2022
# (C) Bruno Raoult ("br"), 2022
# Licensed under the GNU General Public License v3.0 or later.
# Some rights reserved. See LICENSE.
#
# You should have received a copy of the GNU General Public License along with this
# program. If not, see <https://www.gnu.org/licenses/gpl-3.0-standalone.html>.
#
# SPDX-License-Identifier: GPL-3.0-or-later <https://spdx.org/licenses/GPL-3.0-or-later.html>
#

CMD="${0##*/}"
sysdir="/sys/devices/platform/applesmc.768"

declare -al label
declare -A  revlabel

# fan_get - get fan value
# $1: fan
# $2: parameter to get (min, max, input, output, manual, label)
fan_get() {
    local _val fan="$1" param="$2"

    # shellcheck disable=2034
    read -r _val < "$sysdir/fan${fan}_$param"
    printf "%s" "$_val"
}

# fan_set - set fan value
# $1: fan
# $2: parameter to set (manual, min, output)
# $3: new value
fan_set() {
    local fan="$1" param="$2" value="$3"
    local file="$sysdir/fan${fan}_$param"

    [[ -w "$file" ]] || return 1
    printf "%s" "$value" > "$file"
}

# get all fans information
fans_get_info() {
    local -i fan=1
    local -l _label

    while [[ -f "$sysdir/fan${fan}_label" ]]; do
        _label=$(fan_get "$fan" label)
        label[$fan]="$_label"
        revlabel[$_label]=$fan
        (( fan++ ))
    done
}

# fan_maybe_set_control()
# $1 is fan number (starting from 1)
# $2 is "0" for automatic, "1" for manual
fan_maybe_set_control() {
    local -i old fan="$1" value="$2" ret=0
    local -a mode=(auto manual)

    # get previous value
    old=$(fan_get "$fan" manual)
    if [[ "$old" != "$value" ]]; then
        if fan_set "$fan" manual "$value"; then
            printf "'%s' mode set to %s\n" "${label[$fan]}" "${mode[$value]}"
        else
            printf "Try running command as root\n"
            ret=1
        fi
    fi
    return $ret
}

# fan_function() - set fan values (automatic/manual & speed)
# $1 is fan number (starting from 1)
# $2 is "auto" or percent to apply
fan_function() {
    local -i fan="$1" max min speed
    local percent="$2"

    # Get fan data from applesmc.768
    min=$(fan_get "$fan" min)
    max=$(fan_get "$fan" max)

    if [[ "$percent" = "auto" ]]; then
        # Set fan auto mode
        fan_maybe_set_control "$fan" 0 || return 1
    else
        # Set fan manual mode
        fan_maybe_set_control "$fan" 1 || return 1

        # Calculate the net value that will be given to the fans
        # formula : speed = min + [ (max - min) / 100 * percent ]
        speed=$(( min + (max - min) * percent / 100 ))

        # Write the final value to the applemc file
        if fan_set "$fan" output "$speed"; then
            printf "fan set to %d rpm.\n" "$speed"
        else
            printf "Try running command as root\n"
        fi
    fi
}

# get_command() - validate parameter command
# $1 is parameter and should be "auto" or the number/name of a fan
get_command() {
    local param="$1"

    if [[ $param =~ ^[0-9]+$ ]]; then
        param="${label[$param]:-invalid}"
    else
        if [[ $param != "all" && ! -v revlabel["$param"] ]]; then
            param=invalid
        fi
    fi
    printf "%s" "$param"
}

# fan_print() - print fan information
# $1: fan number or "all"
# $2: 'list', 'all', 'speed'
# $3: 'y' or 'n' for header
fan_print() {
    local -a fan=("$1") mode=(auto manual)
    local -i cur
    local todo="$2" header="$3"

    [[ ${fan[0]} = "all" ]] && fan=( "${!label[@]}" )
    {
        if [[ $header = 'y' ]]; then
            case "$todo" in
                list)
                    printf "Fans:\n"
                    ;;
                all)
                    printf "# fan mode speed wanted min max\n"
                    ;;
                speed)
                    printf "fan speed\n"
                    ;;
            esac
        fi
        for cur in "${fan[@]}"; do
            case "$todo" in
                list)
                    printf "%s\n" "${label[$cur]}"
                    ;;
                all)
                    printf "%d %s "  "$cur" "${label[$cur]}"
                    printf "%s "     "${mode[$(fan_get "$cur" manual)]}"
                    printf "%d "     "$(fan_get "$cur" input)"
                    if [[ ${mode[$(fan_get "$cur" manual)]} == "manual" ]]; then
                        printf "%d " "$(fan_get "$cur" output)"
                    else
                        printf "n/a "
                    fi
                    printf "%d %d\n" "$(fan_get "$cur" min)" "$(fan_get "$cur" max)"
                    ;;
                speed)
                    printf "%s %s\n" "${label[$cur]}" "$(fan_get "$cur" input)"
                    ;;

            esac
        done
    } | column -t -R 2,3,4,5,6,7
}

usage() {
    cat <<_EOF
Usage: $CMD [OPTIONS] [FAN] [PERCENT]
View/set FAN speed on a Mac running a Linux operating system.
Optional FAN may be "all", or the number/name of a fan. If FAN is missing, a
list of available fans is printed.
If PERCENT is missing, the speed of FAN is printed. Otherwise, its value should
be "auto" or a value between 0 and 100, and the settings of FAN will be changed
accordingly.

If many formatting options below are specified, the latest will be used.

Options:
    -a, --all       Display all known information on FAN.
    -h, --help      This help.
    -H, --header    When displaying information, add a header line.
    -s, --speed     display only speed.
_EOF
    return 0
}

fans_get_info

SOPTS="ahHs"
LOPTS="all,help,header,speed"

if ! TMP=$(getopt -o "$SOPTS" -l "$LOPTS" -n "$CMD" -- "$@"); then
    log "Use '$CMD --help' for help."
    exit 1
fi
eval set -- "$TMP"
unset TMP

print_type=list
print_header=n
while true; do
    case "$1" in
        -a|--all)
            print_type=all
            ;;
        -h|--help)a
            usage
            exit 0
            ;;
        -H|--header)
            print_header=y
            ;;
        -s|--speed)
            print_type=speed
            ;;
        '--')
            shift
            break
            ;;
    esac
    shift
done

command=""
percent=-1

if (( $# == 0 )); then
    fan_print "all" "$print_type" "$print_header"
    exit 0
else
    command="$(get_command "$1")"
    if [[ $command = "invalid" ]]; then
        printf "%s: no such fan.\n" "$1"
        exit 1
    fi
fi

# fan type and value
if (( $# == 2 )); then
    percent="$2"
else
    [[ $print_type = "list" ]] && print_type="speed"
    fan_print "${revlabel[$command]:-all}" "$print_type" "$print_header"
    exit 0
fi

case "$command" in
    all)
        for fan in "${!label[@]}"; do
            fan_function "$fan" "$percent"
        done
        ;;

    *)
        if [[ -v revlabel["$command"] ]]; then
            fan_function "${revlabel[$command]}" "$percent"
        else
            printf "%s: no such fan 2.\n" "$command"
            exit 1
        fi
        ;;
esac
