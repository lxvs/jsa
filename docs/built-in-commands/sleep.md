---
title: sleep
parent: Built-in Commands
---
## sleep

Sleep certain second(s).
Designed to be used in [scripting].
It prints a message like `Sleep 1.0 second(s)` to stdout unless `-q` is specified.

~~~ console
jsa [<jsa_options>] sleep [<seconds>] [-q]
~~~

\<seconds>
: The number of seconds to sleep, can be a float number.  Default is **1.0**.

-q, --queit, --silent
: Suppress all normal output.

[scripting]: scripting
