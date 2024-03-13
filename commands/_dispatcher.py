from commands._command import JsaCommand
from commands import *

class JsaCommandDispatcher:
    @staticmethod
    def get_instance(name: str) -> JsaCommand:
        if name == 'autosol':
            return autosol.Autosol()
        if name == 'sleep':
            return sleep.Sleep()
        else:
            return None
