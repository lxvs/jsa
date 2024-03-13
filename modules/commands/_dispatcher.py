from modules.commands._command import JsaCommand
from modules.commands.autosol import Autosol

class JsaCommandDispatcher:
    @staticmethod
    def get_instance(name: str) -> JsaCommand:
        if name == 'autosol':
            return Autosol()
        else:
            return None
