class JsaError(Exception):
    pass

class InvalidIpmiTool(JsaError):
    pass

class InvalidArgument(JsaError):
    pass

class JsaScriptError(JsaError):
    pass

class SelfRecursiveError(JsaScriptError):
    pass
