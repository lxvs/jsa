#!/usr/bin/env python3

__version__ = '0.4.0'

import os
import sys
import shutil
import argparse
import subprocess
from enum import Enum
from pathlib import Path

class IpmiTool:
    path: Path | None = None
    version: str | None = None
    type: "IpmiTool.ToolType" = None
    hostname: str | None = None
    username: str | None = None
    password: str | None = None
    interface: str | None = None
    dry_run: bool = False

    class ToolType(Enum):
        IPMITOOL_PATH = 'from IPMITOOL_PATH'
        BUNDLED = 'bundled'
        SHELL = 'from shell'
        ARG = 'from argument'
        NONE = 'none'

    def __init__(
        self,
        hostname: str | None = None,
        username: str | None = None,
        password: str | None = None,
        interface: str | None = None,
        tool_path: str | None = None,
        dry_run: bool = False,
    ) -> None:
        self.type = self.ToolType.NONE
        if tool_path is not None:
            self.path = Path(tool_path)
            self.type = self.ToolType.ARG
        self.get_ipmitool()
        self.hostname = hostname
        self.username = username
        self.password = password
        self.interface = interface
        self.dry_run = dry_run

    def get_ipmitool(self) -> None:
        """
        Get the first executable ipmitool in the following order:
            1. from environment variable IPMITOOL_PATH
            2. bundled ipmitool in ipmitool/
            3. executable ipmitool from shell
        """
        if self.type is self.ToolType.ARG:
            if not self.path.is_file():
                raise InvalidIpmiTool(f"ipmitool not found: {self.path}")
            if not os.access(self.path, os.X_OK):
                raise InvalidIpmiTool(f"ipmitool not executable: {self.path}")
            self.version = self.get_ipmitool_version()
            return

        if os.environ.get('IPMITOOL_PATH') is not None:
            if os.access(os.environ['IPMITOOL_PATH'], os.X_OK):
                self.type = self.ToolType.IPMITOOL_PATH
                self.path = Path(os.environ['IPMITOOL_PATH'])
                self.version = self.get_ipmitool_version()
                return

        bundled_tool = Path(__file__).resolve().parent / 'ipmitool'
        if sys.platform.startswith('linux'):
            bundled_tool = bundled_tool / 'ipmitool'
        elif sys.platform.startswith('win'):
            bundled_tool = bundled_tool / 'ipmitool.exe'
        else:
            bundled_tool = None

        if bundled_tool.is_file() and os.access(bundled_tool, os.X_OK):
            self.type = self.ToolType.BUNDLED
            self.path = bundled_tool
            self.version = self.get_ipmitool_version()
            return

        which = shutil.which('ipmitool')
        if which is not None:
            self.type = self.ToolType.SHELL
            self.path = Path(which)
            self.version = self.get_ipmitool_version()

    def get_ipmitool_version(self) -> str:
        return subprocess.check_output([self.path, '-V'], encoding='utf-8')

    def run(self, args: list) -> int:
        if self.dry_run:
            print(' '.join([str(self.path)] + args))
            return 0

        try:
            subprocess.run([self.path] + args, check=True)
        except subprocess.CalledProcessError as e:
            return e.returncode
        return 0

    def send(self, args: list) -> int:
        real_hostname = self.__process_and_validate_hostname()
        return self.run(
            [
                '-H', real_hostname,
                '-U', self.username,
                '-P', self.password,
                '-I', self.interface,
            ] + args,
        )

    def __process_and_validate_hostname(self) -> str:
        if self.hostname is None:
            raise InvalidArgument("hostname not specified")

        hostname = str(self.hostname)

        if not hostname.replace('.', '').isdigit():
            return hostname

        segments = hostname.strip('.').split('.')
        seg_len = len(segments)
        pref = self.__get_jsa_ip_pref()
        pref_len = len(pref)

        if seg_len > 4 or seg_len + pref_len < 4:
            raise InvalidArgument("invalid IPv4 address")

        slice_end = 4 - seg_len
        return '.'.join(pref[:slice_end] + segments)

    def __get_jsa_ip_pref(self) -> list:
        prefix = os.environ.get('JSA_IP_PREF')
        if prefix is None:
            return []
        if not prefix.replace('.', '').isdigit():
            print(f"warning: ignoring invalid JSA_IP_PREF: {prefix}")
            return []
        return prefix.strip('.').split('.')

class JsaError(Exception):
    pass

class InvalidIpmiTool(JsaError):
    pass

class InvalidArgument(JsaError):
    pass

def get_version(tool: IpmiTool) -> str:
    version = f"jsa {__version__}"
    if tool.type is not IpmiTool.ToolType.NONE:
        version += f", {tool.version} ({tool.type.value})"
    return version

def parse_args():
    parser = argparse.ArgumentParser()
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
        'arguments',
        nargs='+',
        help="arguments to be passed to ipmitool",
    )
    return parser.parse_args()

def main() -> int:
    args = parse_args()

    tool = IpmiTool(
        args.hostname,
        args.username,
        args.password,
        args.interface,
        args.ipmitool_path,
        args.dry_run,
    )

    if args.ipmitool_help:
        return tool.run(['-h'])

    if args.version:
        print(get_version(tool))
        return 0

    if tool.type is IpmiTool.ToolType.NONE:
        raise InvalidIpmiTool(f"ipmitool not found: {tool.path}")

    return tool.send(args.arguments)

def __suppress_traceback(exc_type, exc_val, traceback):
    pass

if __name__ == '__main__':
    try:
        sys.exit(main())
    except JsaError as error:
        print("error:", error, file=sys.stderr)
    except KeyboardInterrupt:
        if sys.excepthook is sys.__excepthook__:
            sys.excepthook = __suppress_traceback
        raise
    sys.exit(1)
