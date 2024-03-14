import sys
from pathlib import Path

def __get_root_path() -> Path:
    if getattr(sys, 'frozen', False):
        path = getattr(sys, '_MEIPASS', sys.executable)
    else:
        path = __file__
    return Path(path).resolve()

ROOT_PATH = __get_root_path()
