# JSA

An ipmitool wrapper.

[Documentation]

It simplifies ipmitool invocation by,

* adding [profile] support (a profile is a combination of any of hostname, username, password,
and interface),
    > `jsa -r node132 power status` instead of `ipmitool -H 192.168.10.132 -U user -P pass -I lanplus power status`
* adding [scripting] support,
    > `jsa -r node132 ps` instead of `ipmitool -H 192.168.10.132 -U user -P pass -I lanplus power status`
* adding some [built-in commands] like autosol,
    > `jsa ... autosol` instead of `ipmitool ... power off; ipmitool ... sol deactivate; ipmitool ... sol activate | tee sol.log`
* [hostname auto completion],
    > `jsa -H 132 ...` instead of `ipmitool -H 192.168.10.132 ...`
* and maybe more in future.

## Installation

### Install Pre-built Binaries

* Download release from [GitHub Releases].
* Extract all contents of the archive to a directory.
* Add that directory to PATH, or add a symlink to jsa executable to a directory in PATH.

### Use from Python Source

* Download or clone source to a directory.
* Invoke jsa by `python3 "/path/to/jsa/main.py" ...`.
* Optionally, use an aliases or a script:
    * On Windows: create `jsa.cmd` in a directory in PATH (such as `C:\\Windows`), with content:
      `python3 "/path/to/jsa/main.py" %*`.
    * On GNU/Linux or Git Bash/Msys2/Cygwin on Windows: add jsa as an alias in your rc file (such as `~/.bashrc`):
      `alias jsa='python3 "/path/to/jsa/main.py" "$@"'`.

[Documentation]: https://lxvs.github.io/jsa
[profile]: https://lxvs.github.io/jsa/profile
[scripting]: https://lxvs.github.io/jsa/scripting
[built-in commands]: https://lxvs.github.io/jsa/built-in-commands
[hostname auto completion]: https://lxvs.github.io/jsa/hostname-auto-completion
[GitHub Releases]: https://github.com/lxvs/jsa/releases
