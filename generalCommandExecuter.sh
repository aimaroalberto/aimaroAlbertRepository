#!/bin/bash

# Functions
print_help() {
    printf "Usage: af [COMMAND] [TARGET]\n"
    printf "Application manager for Aptiv HUs.\n"
    printf "\n"
    printf "COMMAND could be 'install', 'upgrade', 'uninstall', 'start' or 'stop'.\n"
    printf "TARGET could be the absolute path of the jars (used by 'install' and 'upgrade')\n"
    printf "Example: af install /fs/usb0/TestApp-0.1.0.jar\n"
    printf "\n"
    printf "TARGET could be also the AppId of an app already installed (used by 'uninstall', 'start' and 'stop').\n"
    printf "Example: af start TestAppId\n"
    printf "\n"
    printf "Commands shorthands:\n"
    printf "  - 'install' can be replaced by 'i' or 'in'\n"
    printf "  - 'upgrade' can be replaced by 'up' or 'upg'\n"
    printf "  - 'uninstall' can be replaced by 'un' or 'rem'\n"
}

print_try_help() {
    printf "Try 'af --help' for more information.\n"
}

transfer() {
    echo $1
    scp $1 $conn:/tmp
}

fire_command() {
    ssh -q -t $conn "echo '"'id::1\nmethod::'"'$1'"'\nparameters:json:{'"'$2'"'}'"' > /pps/jamaicacar/in"
#   ssh -t $conn "echo '"'id::1\nmethod::'"'$1'"'\nparameters:json:{'"'$2'"'}'"' > /pps/jamaicacar/in"
    # echo "id::1\nmethod::"$1"\nparameters:json:{"$2"}" > /pps/jamaicacar/in
}

check_input() {
    if [ -z "$1" ] && [ -z "$2" ]
    then
        printf "No input supplied.\n"
        print_try_help
        exit 1
    fi

    if [ -z "$1" ]
    then
        printf "Error: command must be supplied.\n"
        print_try_help
        exit 1
    fi

    # Check if the first argument is the help option
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]
    then
        print_help
        exit 0
    fi

    if [ -z "$2" ]
    then
        printf 'Error: target must be supplied.\n'
        print_try_help
        exit 1
    fi
}

# Main execution
check_input $1 $2 

command=$1
target=$2
conn="root@192.168.1.66"

# Replace shorthands with actual commands
if [ "$command" =  "i" ] || [ "$command" =  "in" ]
then
    command="install"
fi

if [ "$command" =  "up" ] || [ "$command" =  "upg" ]
then
    command="upgrade"
fi

if [ "$command" =  "un" ] || [ "$command" =  "rem" ]
then
    command="uninstall"
fi

# Actually perform commands
if [ "$command" =  "install" ] || [ "$command" =  "upgrade" ]
then
    transfer $target # Secure-copy file to tmp 
    filename=$(basename $target) # Get the filename
    fire_command $command "'\"'uri'\"':'\"'file:///tmp/"$filename"'\"'"
elif [ "$command" =  "start" ] || [ "$command" =  "stop" ] || [ "$command" =  "uninstall" ]
then
    fire_command $command "'\"'appId'\"':'\"'"$target"'\"'"
else
    printf 'Input not recognized.\n'
    print_try_help
    exit 1
fi

#       Install:
#           echo "id::1\nmethod::install\nparameters:json:{\"uri\":\"file:///fs/usb0/demovirtualkeyboard-0.4.0-jar-with-dependencies.jar\"}" > /pps/jamaicacar/in
#       upgrade:
#           echo "id::1\nmethod::upgrade\nparameters:json:{\"uri\":\"file:///fs/usb0/demovirtualkeyboard-0.4.0-jar-with-dependencies.jar\"}" > /pps/jamaicacar/in           
#       Start:
#           echo "id::1\nmethod::start\nparameters:json:{\"appId\":\"VirtualKeyboardTestapp\"}" > /pps/jamaicacar/in
#       Stop:
#           echo "id::1\nmethod::stop\nparameters:json:{\"appId\":\"VirtualKeyboardTestapp\"}" > /pps/jamaicacar/in
#       uninstall:
#           echo "id::1\nmethod::uninstall\nparameters:json:{\"appId\":\"VirtualKeyboardTestapp\"}" > pps/jamaicacar/in
