#!/bin/bash
# bash script template by Jasper Phelps. Last update Jan 30, 2022
# Includes:
#   show_help
#   an easy-to-understand argument parsing block (that is, doesn't use getopts) with some examples given
#   fakeable commands

show_help () {
    >&2 echo "\
Short description of the script goes here,
and can continue onto new lines if needed.

Usage: ./bash_script_template.sh arg1 arg2 [-v|--verbose] [-f|--fake] [-n|--number number]

  -v, --verbose: Print more information while running.
  -f, --fake: Don't actually run any commands that would change the filesystem.
  -n, --number N: Specify some number.
"
}

if [ "$#" -eq 0 ] || [ "$1" = "--help" ]; then
    show_help
    exit 1
fi

#DEFAULTS FOR ARGUMENT-MODIFIABLE VARIABLES GO HERE
verbose=false
fake=false
number=7

positionalArgs=()
unknownOptions=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -v|--verbose)  # Use | to separate different ways of specifying the same option
            verbose=true
            >&2 echo "Running verbose"
            shift
            ;;
        -f|--fake)
            fake=true
            >&2 echo "Running fake"
            shift
            ;;
        -n|--number)  # For options that require a value to be specified (like "-n 8" or any other "-[letter] [argument]" pair), use "$2" and "shift; shift"
            number="$2"
            shift; shift
            ;;
        *)  # Catch all other arguments
            if [ " ${1:0:1}" = " -" ]; then  # Ignore arguments starting with - that aren't explicitly listed above
                unknownOptions+=("$1")
                >&2 echo "WARNING: Unknown option $1, ignoring"
            else
                if [ -z "${1/* */}" ]; then
                    >&2 echo "Spaces not allowed inside positional args: $1"
                    exit 1
                fi
                positionalArgs+=("$1")  # Store arguments (other than ones recognized above) in order
            fi
            shift
            ;;
    esac
done
set -- "${positionalArgs[@]}"  # Set the positional arguments, now without any of the options/flags arguments
if [ "$#" -eq 0 ]; then
    show_help
    exit 1
fi

#FAKEABLE COMMANDS GO HERE.
fakeableCommands="rm mv cp mkdir ln chmod realpath sed exit sbatch"
#For the commands listed here, you can use "$command" instead of "command" anywhere in your code that you want the command to echo instead of execute when running in fake mode. For instance, write the line "$mv file1 file2" instead of "mv file1 file2" if you want that line's mv command to not execute when the -f flag is given. If you write "mv file1 file2", then your mv command will happen normally regardless of if -f is given.

if $fake; then
    for cmd in $fakeableCommands; do
        eval $cmd=\"echo \$cmd\"
    done
else
    for cmd in $fakeableCommands; do
        eval $cmd=\"\$cmd\"
    done
fi


#CODE GOES HERE
echo "The first positional argument plus $number is $(( $1 + $number ))"
