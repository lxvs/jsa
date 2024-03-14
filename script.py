import sys
from pathlib import Path

from session import JsaSession
from commands import JsaCommandDispatcher
import exceptions as JsaExceptions

class JsaScript:
    last_cmd: str | None = None

    def __init__(self, cmd: str, file: Path) -> None:
        self.file = file
        self.last_cmd = cmd

    def exec(self, session: JsaSession, argv: list | None = None) -> int:
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
                    retval = self.__dispatch(session, striped.split())
                    if not force and retval != 0:
                        return retval
        except ValueError as e:
            print("error:", e, file=sys.stderr)
            return 1

    def __dispatch(self, session: JsaSession, argv: list) -> int:
        cmd = argv.pop(0)
        cmd_instance = JsaCommandDispatcher.get_instance(cmd)
        if cmd_instance:
            return cmd_instance.exec(session, argv)
        cmd_instance = JsaScriptDispatcher.get_instance(cmd)
        if cmd_instance:
            if cmd_instance.last_cmd == cmd:
                raise JsaExceptions.SelfRecursiveError(f"self recursive script: {cmd}")
            return cmd_instance.exec(session, argv)
        return session.send([cmd] + argv)

class JsaScriptDispatcher:
    dir: str = 'scripts'
    ext: str = 'txt'
    path: Path = Path(__file__).resolve().parent / dir

    @classmethod
    def get_instance(cls, name: str) -> JsaScript:
        file = cls.path / name
        if cls.ext:
            file = file.with_suffix('.' + cls.ext)
        if file.exists() and file.is_file():
            return JsaScript(name, file)
        return None
