import os
import sys
import shutil
import subprocess
from enum import Enum
from pathlib import Path

import definitions
import exceptions as JsaExceptions
from ipmi_profile import IpmiProfile

class ToolType(Enum):
    IPMITOOL_PATH = 'from IPMITOOL_PATH'
    BUNDLED = 'bundled'
    SHELL = 'from shell'
    ARG = 'from argument'
    NONE = ''

class JsaSession:
    def __init__(
        self,
        hostname: str = '',
        username: str = '',
        password: str = '',
        interface: str = '',
        tool_path: str = '',
        dry_run: bool = False,
        profile: str = '',
    ) -> None:
        self.type: ToolType = ToolType.NONE
        self.tool_valid: bool = False
        if tool_path:
            self.path = Path(tool_path)
            self.type = ToolType.ARG
            self.validate_tool()
            self.version = self.__get_ipmitool_version()
        if self.type is ToolType.NONE:
            self.get_ipmitool()
        __profile = IpmiProfile(profile)
        self.hostname = self.__parse_hostname(hostname) or self.__parse_hostname(__profile.hostname)
        self.username = username or __profile.username
        self.password = password or __profile.password
        self.interface = interface or __profile.interface
        self.dry_run = dry_run
        self.session_valid = False

    def get_ipmitool(self) -> None:
        """
        Get the first executable ipmitool in the following order:

            1. from environment variable IPMITOOL_PATH
            2. bundled ipmitool in ipmitool/
            3. executable ipmitool from shell
        """
        if os.environ.get('IPMITOOL_PATH') is not None:
            if os.access(os.environ['IPMITOOL_PATH'], os.X_OK):
                self.type = ToolType.IPMITOOL_PATH
                self.path = Path(os.environ['IPMITOOL_PATH'])
                self.version = self.__get_ipmitool_version()
                return

        bundled_tool = definitions.ROOT_PATH.with_name('ipmitool')
        if sys.platform.startswith('linux'):
            bundled_tool = bundled_tool / 'ipmitool'
        elif sys.platform.startswith('win'):
            bundled_tool = bundled_tool / 'ipmitool.exe'
        else:
            bundled_tool = None

        if bundled_tool and bundled_tool.is_file() and os.access(bundled_tool, os.X_OK):
            self.type = ToolType.BUNDLED
            self.path = bundled_tool
            self.version = self.__get_ipmitool_version()
            return

        which = shutil.which('ipmitool')
        if which is not None:
            self.type = ToolType.SHELL
            self.path = Path(which)
            self.version = self.__get_ipmitool_version()
            return

    def __get_ipmitool_version(self) -> str:
        return subprocess.check_output([self.path, '-V'], encoding='utf-8').strip()

    def send(
            self,
            args: list,
            stdin = None,
            stdout = None,
            stderr = None,
            check = True,
    ) -> int:
        self.validate()
        full_args = self.construct_full_ipmi_args(args)
        if self.dry_run:
            print(' '.join(full_args))
            return 0
        try:
            subprocess.run(
                full_args,
                stdin=stdin,
                stdout=stdout,
                stderr=stderr,
                check=check,
            )
        except subprocess.CalledProcessError as e:
            return e.returncode
        return 0

    def construct_full_ipmi_args(self, args: list[str]) -> list[str]:
        return [str(self.path)] + self.get_profile_args() + args

    def get_profile_args(self) -> list[str]:
        return ['-H', self.hostname, '-U', self.username, '-P', self.password, '-I', self.interface]

    def validate(self) -> None:
        self.validate_tool()
        self.validate_session()

    def validate_tool(self) -> None:
        if self.tool_valid:
            return
        if self.type is ToolType.NONE:
            raise JsaExceptions.InvalidIpmiTool("ipmitool not found")
        if not self.path.is_file():
            raise JsaExceptions.InvalidIpmiTool(f"invalid ipmitool: {self.path}")
        if not os.access(self.path, os.X_OK):
            raise JsaExceptions.InvalidIpmiTool(f"ipmitool not executable: {self.path}")
        self.tool_valid = True

    def validate_session(self) -> None:
        if self.session_valid:
            return
        if self.hostname is None:
            raise JsaExceptions.InvalidArgument("hostname not specified")
        self.session_valid = True

    def __parse_hostname(self, hostname) -> str:
        if not hostname:
            return hostname

        if not hostname.replace('.', '').isdigit():
            return hostname

        segments = hostname.strip('.').split('.')
        seg_len = len(segments)
        pref = self.__get_jsa_ip_pref()
        pref_len = len(pref)

        if seg_len > 4 or seg_len + pref_len < 4:
            raise JsaExceptions.InvalidArgument("invalid IPv4 address")

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
