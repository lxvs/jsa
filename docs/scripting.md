---
title: Scripting
nav_order: 3
---
# Scripting

You can write a sequence of commmands to file `scripts/<name>.txt`, and execute them by `<name>`.

~~~ console
jsa [<jsa_options>] <name> [<argument> ...]
~~~

\<name>
: Script name without `.txt`.

\<argument>
: Arguments passed to the script.  They can be refered by `$@` or `$1` in scripts.
See also [Arguments](#arguments).

## Syntax

~~~
[!] <command> [<argument> ...]
...
~~~

Line `COMMAND ARGUMENT` will be executed as `jsa COMMAND ARGUMENT`.

Script content is executed line by line.
Unless prefixed with `!`, the script will abort on error.

## Comments

Lines starting with `#` are comments and have no effect, as well as empty lines.

{:.note}
`#` can only be at the first column of a line to make it a comment line.

## Arguments

Arguments passed to scripts can be refered by special notations.

$@, $*
: All arguments.  Currently `$@` and `$*` are equivalent.

$1, $2, ...
: `$1` is the first argument, `$2` the second, etc.
The max number is up to the shell capacity.

$#
: The number of arguments.

{:.note}
> Place ipmitool options after the script name when running on command line,
> because if not, the script name will be passed to ipmitool as one of arguments.
>
> However, if you want to pass common flags (such as `-N1`) rather than command argument,
> place the `$@` before the command in scripts.
