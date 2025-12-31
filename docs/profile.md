---
title: Profile
nav_order: 2
---
# Profile

A profile is a combination of any of hostname, username, password, and interface.
It's defined in file `profile.toml` located in the same directory with `jsa`.

Let's take the below content of `profile.toml` as an example:

~~~ toml
[default]
username = "admin"
password = "admin"
interface = "lanplus"

[example]
hostname = "example.com"

[root]
username = "root"
password = "root"
~~~

The name in brackets (**default**, **example**, and **root** in this example) is the **profile name**.
The **default** profile is a special one -- it's always loaded, even when other profile is loaded, acting as a set
of fallback values.

With the above profile.toml, the below 3 commands are equivalent:

~~~ console
jsa -r example mc info
jsa -H example.com mc info
ipmitool -H example.com -U admin -P admin -I lanplus mc info
~~~

Profile elements can be overridden by **-H**, **-U**, **-P**, and **-I**, so the below commands are equivalent:

~~~ console
jsa -r root -H example.net -P newpass mc info
ipmitool -H example.net -U root -P newpass -I lanplus mc info
~~~

Except for **default** profile, only one profile can be used for a session.
If multiple profiles are specified, only the last one takes effect.  Below commands are equivalent:

~~~ console
jsa -r root -r example mc info
jsa -r example mc info
ipmitool -H example.com -U admin -P admin -I lanplus mc info
~~~
