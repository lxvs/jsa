import os
import sys
import time
import argparse
import colorama
import subprocess
from pathlib import Path

from session import JsaSession
import exceptions as JsaExceptions

class JsaCommand:
    def exec(self, session: JsaSession, argv: list | None = None) -> int:
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

    def exec(self, session: JsaSession, argv: list | None = None) -> int:
        argv = argv or []
        args = self.__parseargs(argv)
        deactivate: bool = args.deactivate
        power_off: bool = args.power_off
        sleep: float = args.sleep
        power_on: bool = args.power_on
        log: bool = args.log
        output: str = args.output
        d: bool = args.deactivate_and_activate
        a: bool = args.activate_only
        if d and a:
            raise JsaExceptions.InvalidArgument(
                "--deactivate-and-activate and --activate-only cannot be used together",
            )
        session.validate()
        if d or a:
            power_off = False
            power_on = False
        if a:
            deactivate = False
        if log:
            output_parsed = self.__parse_output(session, output)
            stdout = subprocess.PIPE
            stderr = subprocess.STDOUT
        else:
            output_parsed = None
            stdout = None
            stderr = None
        if deactivate:
            session.send(['sol', 'deactivate'], stderr=subprocess.DEVNULL, check=False)
        if power_off:
            session.send(['chassis', 'power', 'off'], check=False)
            if sleep > 0:
                Sleep.exec(None, [str(sleep)])
        if power_on:
            session.send(['chassis', 'power', 'on'], check=False)
        proc = subprocess.Popen(
            session.construct_full_ipmi_args(['sol', 'activate']),
            stdout=stdout,
            stderr=stderr,
        )
        if output_parsed:
            colorama.just_fix_windows_console()
            with open(output_parsed, 'w', encoding='utf-8', errors='ignore') as sol_log:
                while byte := proc.stdout.read(1):
                    char = byte.decode(encoding='utf-8', errors='ignore')
                    sys.stdout.write(char)
                    sys.stdout.flush()
                    sol_log.write(char)
                    sol_log.flush()
        return proc.wait()

    def __parseargs(self, argv: list):
        parser = argparse.ArgumentParser(
            allow_abbrev=False,
            description="Deactivate SOL session, power off, sleep 10 seconds, power on, and activate SOL.",
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
            '--power-off',
            action='store_true',
            default=True,
            help="Perform power off (default)",
        )
        parser.add_argument(
            '--no-power-off',
            dest='power_off',
            action='store_false',
            help="Do not perform power off, and disable --sleep",
        )
        parser.add_argument(
            '--sleep',
            type=float,
            metavar='SECONDS',
            help="time to sleep after performing power off (default %(default)s)",
            default=10.0,
        )
        parser.add_argument(
            '--power-on',
            action='store_true',
            default=True,
            help="Perform power on (default)",
        )
        parser.add_argument(
            '--no-power-on',
            dest='power_on',
            action='store_false',
            help="Do not perform power on",
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
        parser.add_argument(
            '-d',
            '--deactivate-and-activate',
            action='store_true',
            help="shortcut for --no-power-off and --no-power-on",
        )
        parser.add_argument(
            '-a',
            '--activate-only',
            action='store_true',
            help="shortcut for --no-deactivate, --no-power-off, and --no-power-on",
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
    @staticmethod
    def exec(_: JsaSession, argv: list | None = None) -> int:
        argv = argv or []
        args = Sleep.__parseargs(argv)
        seconds: float = args.seconds
        quiet: bool = args.quiet
        if not quiet:
            print(f"Sleep {seconds} second(s)")
        time.sleep(seconds)

    @staticmethod
    def __parseargs(argv: list):
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
        parser.add_argument(
            "-q",
            "--quiet",
            "--silent",
            action='store_true',
            help="suppress all normal output",
        )
        return parser.parse_args(argv)
