#!/usr/bin/env python3

__version__ = '0.4.0'

import sys
import argparse
import subprocess

import modules.commands as JsaCommands
import modules.exceptions as JsaExceptions
from modules.session import JsaSession

def get_version(session: JsaSession) -> str:
    version = f"jsa {__version__}"
    if session.type is not JsaSession.ToolType.NONE:
        version += f", {session.version} ({session.type.value})"
    return version

def __parse_args():
    parser = argparse.ArgumentParser(
        allow_abbrev=False,
        add_help=False,
    )
    parser.add_argument(
        '-h',
        '--help',
        action='store_true',
        help="Print help and exit; can be used with commands",
    )
    parser.add_argument(
        '-V',
        '--version',
        action='store_true',
        help="Print version and exit",
    )
    parser.add_argument(
        '-H',
        '--hostname',
        help="Remote host name for LAN interface",
    )
    parser.add_argument(
        '-U',
        '--username',
        default="admin",
    )
    parser.add_argument(
        '-P',
        '--password',
        default="admin",
    )
    parser.add_argument(
        '-I',
        '--interface',
        default="lanplus",
    )
    parser.add_argument(
        '--ipmitool-path',
        help="path to ipmitool to be used this time only",
    )
    parser.add_argument(
        '--ipmitool-help',
        action='store_true',
        help="Show help information of ipmitool",
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help="Print command and arguments and exit.",
    )
    parser.add_argument(
        'command',
        nargs='?',
        help="command to be executed (jsa, custom, or IPMI command)",
    )
    parser.add_argument(
        'arguments',
        nargs='*',
        help="arguments of the command",
    )

    args, cmd_args = parser.parse_known_args()
    if args.help:
        if args.command:
            cmd_args += ['--help']
        else:
            parser.print_help()
            sys.exit(0)

    return args, cmd_args

def main() -> int:
    args, cmd_args = __parse_args()

    session = JsaSession(
        args.hostname,
        args.username,
        args.password,
        args.interface,
        args.ipmitool_path,
        args.dry_run,
    )

    if args.ipmitool_help:
        subprocess.run([session.path, '-h'], check=False)
        return 0

    if args.version:
        print(get_version(session))
        return 0

    return dispatch(session, args.command, args.arguments + cmd_args)

def dispatch(session: JsaSession, cmd: str, cmd_args: list) -> int:
    if hasattr(JsaCommands, cmd):
        cmd_instance = getattr(JsaCommands, cmd)
        return cmd_instance(session, cmd_args)
    return session.send([cmd] + cmd_args)

if __name__ == '__main__':
    try:
        sys.exit(main())
    except JsaExceptions.JsaError as error:
        print("error:", error, file=sys.stderr)
    except KeyboardInterrupt:
        print("KeyboardInterrupt", file=sys.stderr)
    sys.exit(1)
