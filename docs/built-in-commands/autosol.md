---
title: autosol
parent: Built-in Commands
---
# autosol

This command is a wrapper of ipmitool sol command, adding features such as logging.

~~~ console
jsa [<jsa_options>] autosol [<option> ...]
~~~

-h, --help
: Show help message and exit.

--deactivate
: Deactivate previous possibly activated SOL session.  This is the default.

--no-deactivate
: Do not deactivate previous possibly activated SOL session

--power-off
: Perform power off. This is the default.

--no-power-off
: Do not perform power off, and disable `--sleep`.

--sleep SECONDS
: Time to sleep after performing power off.  Default is 10.0.

--power-on
: Perform power on.  This is the default.

--no-power-on
: Do not perform power on.

--log
: Save SOL output to file.  This is the default.  See also `--output`.

--no-log
: Do not save SOL output to file; this ignores `--output`.

-o, --output OUTPUT
: path of the log file for the SOL output (can be a directory).
$(hostname) will be replaced to actual hostname. Date and time format is the same with strftime.
(default: `autosol-$(hostname)-%Y%m%d-%H%M%S.log`)

-d, --deactivate-and-activate
: Shortcut for `--no-power-off` and `--no-power-on`

-a, --activate-only
: Shortcut for `--no-deactivate`, `--no-power-off`, and `--no-power-on`.
