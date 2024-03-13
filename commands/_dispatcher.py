from commands._command import JsaCommand
from commands.autosol import Autosol
from commands.sleep import Sleep

class JsaCommandDispatcher:
    @staticmethod
    def get_instance(name: str) -> JsaCommand:
        if name == 'autosol':
            return Autosol()
        if name == 'sleep':
            return Sleep()
        else:
            return None
