import sys
import time
import argparse
import subprocess

from modules.session import JsaSession

def autosol(session: JsaSession, argv: list) -> int:
    args = __autosol_parseargs(argv)
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
    with open('sol.log', 'w', encoding='utf-8', errors='ignore') as sol_log:
        for line in proc.stdout:
            line_str = line.decode(encoding='utf-8', errors='ignore')
            sys.stdout.write(line_str)
            sol_log.write(line_str)
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
    return parser.parse_args(argv)
