# Put custom scripts here with filename custom_command.txt, and `jsa custom_command' will load the script and
#  execute it line by line.
#
# Lines starting with `#' are commments and will be ignored by jsa.
#
# Prepend `!' to a line to continue script execution when error code of this line is not zero.
#
# $@ will be replaced with script arguments.
# $1, $2, ... will be replaced with the script argument of that position.
#
# For example, with scripts/example.txt with below content:
#     lan print $1
#
# Calling `jsa example 5' has the same effect of `jsa lan print 5'.
#
# Place ipmitool options after the script name when running on command line, but place the $@ before the command
#  in scripts.
# Take scripts/ps.txt as an example:
#     $@ chassis power status
#
# To pass -N1 -R1 to this script, use `jsa ps -N1 -R1' instead of `jsa -N1 -R1 ps'.
#
# There are some additional commands for scripts:
#     echo: print some texts to stdout
#     sleep: wait some seconds, can be float number like 0.5

echo read scripts/readme.txt for help on custom commands
