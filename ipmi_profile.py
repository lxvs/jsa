import tomllib
from pathlib import Path
from definitions import ROOT_PATH


HOSTNAME = 'hostname'
USERNAME = 'username'
PASSWORD = 'password'
INTERFACE = 'interface'

class IpmiProfile:
    hostname: str = ''
    username: str = ''
    password: str = ''
    interface: str = ''

    def __init__(self, profile_name: str, toml: Path | None = None) -> None:
        if not profile_name:
            return
        if not toml:
            toml = ROOT_PATH.with_name('profiles.toml')
        with open(toml, 'rb') as f:
            cfg: dict[str, dict[str, str]] = tomllib.load(f)
        if profile_name not in cfg:
            raise KeyError(f"profile {profile_name} not found")
        self.hostname=cfg[profile_name].get(HOSTNAME) or cfg['default'].get(HOSTNAME) or ''
        self.username=cfg[profile_name].get(USERNAME) or cfg['default'].get(USERNAME) or ''
        self.password=cfg[profile_name].get(PASSWORD) or cfg['default'].get(PASSWORD) or ''
        self.interface=cfg[profile_name].get(INTERFACE) or cfg['default'].get(INTERFACE) or ''
