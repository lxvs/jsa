from modules.session import JsaSession

class JsaCommand:
    def exec(self, session: JsaSession, argv: list) -> int:
        raise NotImplementedError("exec not implemented")
