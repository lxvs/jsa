import os
import sys
import time
import argparse
import subprocess
from pathlib import Path

from session import JsaSession

class JsaCommand:
    def exec(self, session: JsaSession, argv: list) -> int:
        raise NotImplementedError("exec not implemented")

class JsaCommandDispatcher:
    @staticmethod
    def get_instance(name: str) -> JsaCommand:
        if name == 'autosol':
            return Autosol()
        if name == 'sleep':
            return Sleep()
        else:
            return None

class Autosol(JsaCommand):
    DEFAULT_OUTPUT = r'autosol-$(hostname)-%Y%m%d-%H%M%S.log'

    def exec(self, session: JsaSession, argv: list) -> int:
        args = self.__parseargs(argv)
        session.validate()
        output = self.__parse_output(session, args.output)
        if not args.activate_only:
            if args.deactivate:
                session.send(['sol', 'deactivate'], stderr=subprocess.DEVNULL, check=False)
            if not args.off:
                session.send(['chassis', 'power', 'off'], check=False)
                if args.sleep > 0:
                    time.sleep(args.sleep)
            session.send(['chassis', 'power', 'on'], check=False)
        proc = subprocess.Popen(
            session.construct_full_ipmi_args(['sol', 'activate']),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        with open(output, 'w', encoding='utf-8', errors='ignore') as sol_log:
            while True:
                byte = proc.stdout.read(1)
                if byte:
                    char = byte.decode(encoding='utf-8', errors='ignore')
                    sys.stdout.write(char)
                    sys.stdout.flush()
                    sol_log.write(char)
                    sol_log.flush()
                else:
                    break
        return proc.wait()

    def __parseargs(self, argv: list):
        parser = argparse.ArgumentParser(
            allow_abbrev=False,
            description="Deactivate SOL session, power off, sleep 10 seconds, power on, and activate SOL.",
        )
        parser.add_argument(
            '-a',
            '--activate-only',
            action='store_true',
            help="Only activate SOL",
        )
        parser.add_argument(
            '--sleep',
            type=float,
            help="time to sleep (default %(default)s)",
            default=10.0,
        )
        parser.add_argument(
            '--off',
            action='store_true',
            help="System is already off (do not power off)",
        )
        parser.add_argument(
            '--deactivate',
            action='store_true',
            default=True,
            help="Deactivate previous possibly activated SOL session (default)",
        )
        parser.add_argument(
            '--no-deactivate',
            dest='deactivate',
            action='store_false',
            help="Do not deactivate previous possibly activated SOL session",
        )
        parser.add_argument(
            '--log',
            action='store_true',
            default=True,
            help="Save SOL output to file (default); see also --output",
        )
        parser.add_argument(
            '--no-log',
            dest='log',
            action='store_false',
            help="Do not save SOL output to file; this ignores --output",
        )
        parser.add_argument(
            '-o',
            '--output',
            help="path of the log file for the SOL output (can be a directory). " \
                + "$(hostname) will be replaced to actual hostname. " \
                + "Date and time format is the same with strftime. " \
                + "(default: %(default)s)",
            default=self.DEFAULT_OUTPUT,
        )
        return parser.parse_args(argv)

    def __parse_output(self, session: JsaSession, output: str) -> str:
        path = Path(output)
        if path.is_dir():
            output = str(path / self.DEFAULT_OUTPUT)
        elif output.endswith(os.sep) or (os.altsep and output.endswith(os.altsep)):
            path.mkdir(parents=True)
            output = str(path / self.DEFAULT_OUTPUT)
        elif not path.parent.exists():
            path.parent.mkdir(parents=True)
        output = output.replace('$(hostname)', session.hostname)
        local_time = time.localtime(time.time())
        return time.strftime(output, local_time)

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
