from modules.commands._command import JsaCommand
from modules.commands.autosol import Autosol
from modules.commands.sleep import Sleep

class JsaCommandDispatcher:
    @staticmethod
    def get_instance(name: str) -> JsaCommand:
        if name == 'autosol':
            return Autosol()
        if name == 'sleep':
            return Sleep()
        else:
            return None
