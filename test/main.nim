import napi, macros

init proc(exports: Module) =
  fn(2, bob):
    result = %(args[0].getInt + 2)

  exports.register("hello", {
      "some_property": %["some value", "value", "other value"],
      "jim": bob
  })

  exports.registerFn(5, "goodbye"):
    % "fuck"
