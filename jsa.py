#!/usr/bin/env python3

import os
import sys
import argparse
import subprocess
from enum import Enum
from dataclasses import dataclass

__version__ = '0.4.0'

class IpmiTool:
    path : str
    version : str
    type : "ToolType"

    class ToolType(Enum):
        IPMITOOL_PATH = 'from IPMITOOL_PATH'
        BUNDLED = 'bundled'
        SHELL = 'from shell'
        NONE = 'none'

    def __init__(self) -> None:
        self.get_ipmitool()

    def get_ipmitool(self) -> None:
        """
        Get the first executable ipmitool in the following order:
            1. from environment variable IPMITOOL_PATH
            2. bundled ipmitool in ipmitool/
            3. executable ipmitool from shell
        """
        self.path = os.path.join(os.environ['ProgramFiles'], 'Git', 'usr', 'bin', 'printf.exe')
        self.version = '1.1.18'
        self.type = self.ToolType.NONE

def get_version() -> str:
    version = f"jsa {__version__}"
    tool = IpmiTool()
    if tool.type is not IpmiTool.ToolType.NONE:
        version += f", ipmitool {tool.version} ({tool.type.value})"
    return version

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-V', '--version', action='version', version=f"{get_version()}")
    parser.add_argument('-H', '--hostname')
    parser.add_argument('-U', '--username', default="admin")
    parser.add_argument('-P', '--password', default="admin")
    parser.add_argument('-I', '--interface', default="lanplus")
    parser.add_argument('arguments', nargs='*')
    return parser.parse_args()

def main() -> int:
    args = parse_args()
    tool = IpmiTool()
    cmd = [tool.path, '%s\\n']
    cmd += args.arguments
    subprocess.run(cmd, check=True)

if __name__ == '__main__':
    sys.exit(main())
