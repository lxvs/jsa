import sys
from pathlib import Path

import definitions
from session import JsaSession
from commands import JsaCommandDispatcher
import exceptions as JsaExceptions

class JsaScript:
    last_cmd: str | None = None

    def __init__(self, argv: list[str], file: Path) -> None:
        self.argv = argv
        self.file = file
        self.argc = len(argv)

    def exec(self, session: JsaSession) -> int:
        try:
            with open(self.file) as file:
                for line in file:
                    striped = line.strip()
                    if not striped or striped[0] == '#':
                        continue
                    force = False
                    if striped[0] == '!':
                        force = True
                        striped = striped[1:].strip()
                    cmd = self.process_dollars(striped)
                    JsaScript.last_cmd = self.argv[0]
                    retval = self.__dispatch(session, cmd.split())
                    if not force and retval != 0:
                        return retval
        except ValueError as e:
            print("error:", e, file=sys.stderr)
            return 1
        return 0

    def process_dollars(self, line: str) -> str:
        if '$' not in line:
            return line
        processed = ''
        stack = 0
        last_index = len(line) - 1
        ALL_DIGITS = '0123456789'
        VALID_SPECIFIER = {
            '$',    # a `$' character
            '@',    # all arguments
            '*',    # all arguments, exactly the same with `@' for now
            '#',    # number of arguments after script name
        }
        for i in range(0, last_index + 1):
            if stack:
                stack -= 1
                continue
            if line[i] == '$':
                if i + 1 > last_index:
                    processed += '$'
                    continue
                stack += 1
                if line[i + stack] in VALID_SPECIFIER:
                    if line[i + stack] == '$':
                        processed += '$'
                        continue
                    if line[i + stack] == '@':
                        processed += ' '.join(self.argv[1:])
                        continue
                    if line[i + stack] == '*':
                        processed += ' '.join(self.argv[1:])
                        continue
                    if line[i + stack] == '#':
                        processed += str(self.argc - 1)
                        continue
                while i + stack <= last_index and line[i + stack] in ALL_DIGITS:
                    stack += 1
                n = int(line[i + 1 : i + stack + 1])
                if self.argc - 1 < n:
                    raise JsaExceptions.JsaScriptError(
                        f"too few arguments, at least {n} required by script `{self.argv[0]}'"
                    )
                processed += self.argv[n]
                continue
            processed += line[i]
        return processed

    def __dispatch(self, session: JsaSession, argv: list[str]) -> int:
        cmd = argv[0]
        cmd_instance = JsaCommandDispatcher.get_instance(argv)
        if cmd_instance:
            return cmd_instance.exec(session)
        cmd_instance = JsaScriptDispatcher.get_instance(argv)
        if cmd_instance:
            if JsaScript.last_cmd == cmd:
                raise JsaExceptions.SelfRecursiveError(f"self recursive script: {cmd}")
            return cmd_instance.exec(session)
        return session.send(argv)

class JsaScriptDispatcher:
    dir: str = 'scripts'
    ext: str = 'txt'
    path: Path = definitions.ROOT_PATH.with_name(dir)

    @classmethod
    def get_instance(cls, argv: list[str]) -> JsaScript | None:
        file = cls.path / argv[0]
        if cls.ext:
            file = file.with_suffix('.' + cls.ext)
        if file.exists() and file.is_file():
            return JsaScript(argv, file)
        return None
