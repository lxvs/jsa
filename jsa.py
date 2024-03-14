#!/usr/bin/env python3

__version__ = '0.4.0'

import sys
import argparse
import subprocess

import exceptions as JsaExceptions
from session import JsaSession
from commands import JsaCommandDispatcher
from script import JsaScriptDispatcher

def get_version() -> str:
    version = f"jsa {__version__}"
    JsaSession.get_ipmitool()
    if JsaSession.type is not JsaSession.ToolType.NONE:
        version += f", {JsaSession.version} ({JsaSession.type.value})"
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
        action='version',
        version=get_version(),
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

    if args.ipmitool_help:
        session.validate_tool()
        subprocess.run([session.path, '-h'], check=False)
        return 0

    if args.command is None:
        parser.print_help()
        sys.exit(1)
    elif args.help:
        return dispatch(session, args.command, ['--help'])
    return dispatch(session, args.command, args.arguments + cmd_args)

def dispatch(session: JsaSession, cmd: str, cmd_args: list) -> int:
    cmd_instance = JsaCommandDispatcher.get_instance(cmd)
    if cmd_instance:
        return cmd_instance.exec(session, cmd_args)
    cmd_instance = JsaScriptDispatcher.get_instance(cmd)
    if cmd_instance:
        return cmd_instance.exec(session, cmd_args)
    return session.send([cmd] + cmd_args)

if __name__ == '__main__':
    try:
        sys.exit(main())
    except JsaExceptions.JsaError as error:
        print("error:", error, file=sys.stderr)
    except KeyboardInterrupt:
        print("KeyboardInterrupt", file=sys.stderr)
    sys.exit(1)
