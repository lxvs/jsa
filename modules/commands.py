import sys
import time
import argparse
import subprocess

from modules.session import JsaSession

DEFAULT_SOL_OUTPUT = 'sol-%(hostname)-%Y%m%d-%H%M%S.log'

def autosol(session: JsaSession, argv: list) -> int:
    args = __autosol_parseargs(argv)
    output = parse_output(session, args.output)
    if args.deactivate:
        session.send(['sol', 'deactivate'], stderr=subprocess.DEVNULL, check=False)
    if not args.off:
        session.send(['chassis', 'power', 'off'], check=False)
        time.sleep(10)
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

def __autosol_parseargs(argv: list):
    parser = argparse.ArgumentParser(
        allow_abbrev=False,
        description="Deactivate SOL session, power off, sleep 10 seconds, power on, and activate SOL.",
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
        help=f"path of the log file for the SOL output (default: {DEFAULT_SOL_OUTPUT})",
        default=DEFAULT_SOL_OUTPUT,
    )
    return parser.parse_args(argv)

def parse_output(session: JsaSession, output: str) -> str:
    return time.strftime(
        output.replace('%(hostname)', session.hostname),
        time.localtime(time.time())
    )
