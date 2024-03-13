import time
import argparse

from session import JsaSession
from commands._command import JsaCommand

class Sleep(JsaCommand):
    def exec(self, session: JsaSession, argv: list) -> int:
        args = self.__parseargs(argv)
        time.sleep(args.seconds)

    def __parseargs(self, argv: list):
        parser = argparse.ArgumentParser(
            allow_abbrev=False,
            description="Sleep a given number of seconds.",
        )
        parser.add_argument(
            "seconds",
            nargs='?',
            type=float,
            default=1.0,
            help="The number of seconds to sleep (default: %(default)s)",
        )
        return parser.parse_args(argv)
