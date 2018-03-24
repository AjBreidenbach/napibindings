import bindings, macros

init proc(exports: NapiNode) =
  exports.register("hello", "hello world")
  exports.registerFn("cushy", 1):
    echo args[0].getStr
  exports.registerFn("fib", 1):
    result = e.create({
      "somenumber": e.create([e.create(args[0].getInt), e.create(15)]),
      "othervar": e.create("hi")
    })
    echo cast[int](e.getProperty(result, "othe"))

