import bindings, macros

init proc(exports: NapiNode) =
  exports.register("hello", "hello world")
  exports.registerFn("cushy", 1):
    echo args[0].getStr
