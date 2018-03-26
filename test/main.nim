import bindings, macros

init proc(exports: NapiNode) =
  exports.register("hello", {"some_property":
    %["some value", "value", "other value"]
  })
  exports.registerFn("foo", 2):
    result =  %(args[0].getInt + 2)
