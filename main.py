#!/usr/bin/env python3

__version__ = '0.4.0'

import sys
import argparse
import subprocess

import exceptions as JsaExceptions
from session import JsaSession
from commands import JsaCommandDispatcher
from script import JsaScriptDispatcher

def get_version(session: JsaSession) -> str:
    version = f"jsa {__version__}"
    if session.type is not JsaSession.ToolType.NONE:
        version += f", {session.version} ({session.type.value})"
    return version

def __parse_args() -> argparse.ArgumentParser:
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
        help="command to be executed (built-in command, script, or IPMI command)",
    )
    parser.add_argument(
        'arguments',
        nargs='*',
        help="arguments of the command",
    )

    return parser

def main() -> int:
    parser = __parse_args()
    args, cmd_args = parser.parse_known_args()

    session = JsaSession(
        args.hostname,
        args.username,
        args.password,
        args.interface,
        args.ipmitool_path,
        args.dry_run,
    )

    if args.version:
        print(get_version(session))
        return 0

    if args.ipmitool_help:
        session.validate_tool()
        subprocess.run([session.path, '-h'], check=False)
        return 0

    if args.command is None:
        parser.print_help()
        return 1
    elif args.help:
        return dispatch(session, [args.command, '--help'])
    return dispatch(session, [args.command] + args.arguments + cmd_args)

def dispatch(session: JsaSession, argv: list[str]) -> int:
    if cmd_instance := JsaCommandDispatcher.get_instance(argv):
        return cmd_instance.exec(session)
    if cmd_instance := JsaScriptDispatcher.get_instance(argv):
        return cmd_instance.exec(session)
    return session.send(argv)

if __name__ == '__main__':
    try:
        sys.exit(main())
    except JsaExceptions.JsaError as error:
        print("error:", error, file=sys.stderr)
    except KeyboardInterrupt:
        print("KeyboardInterrupt", file=sys.stderr)
    sys.exit(1)
