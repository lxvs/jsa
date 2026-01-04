---
title: Home
description: JSA is an ipmitool wrapper that simplifies its invocation.
nav_order: 1
---
# JSA

An ipmitool wrapper.

It simplifies ipmitool invocation by,

* adding [profile] support (a profile is a combination of any of hostname, username, password,
and interface),
* adding [scripting] support,
* adding some [built-in commands] like autosol,
* [hostname auto completion],
* and maybe more in future.

## Usage

~~~ console
jsa [<options>] <command> [<argument> ...]
~~~

\<command>
: An IPMI command or a [built-in commands].
  Use `jsa <command> --help` for usage on a specific built-in command.

-h, \--help
: Print help and exit; can be used with commands

-V, \--version
: Print version and exit

-H, \--hostname HOSTNAME
: Remote host name for ipmitool commands.

-U, \--username USERNAME
: Username of remote host for ipmitool commands.

-P, \--password PASSWORD
: Password of remote host for ipmitool commands.

-I, \--interface INTERFACE
: Interface for ipmitool commands.

-r, \--profile PROFILE
: Load [profile] from `profiles.toml`.
It has lower priority than -H, -U, -P, and -I.

\--ipmitool-path IPMITOOL_PATH
: Path to ipmitool executable to be used this time only.

\--ipmitool-help
: Show help information of ipmitool.

\--dry-run
: Print the command and arguments that would be executed and exit.

[profile]: profile
[scripting]: scripting
[built-in commands]: built-in-commands
[hostname auto completion]: hostname-auto-completion
