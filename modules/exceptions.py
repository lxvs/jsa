class JsaError(Exception):
    pass

class InvalidIpmiTool(JsaError):
    pass

class InvalidArgument(JsaError):
    pass
