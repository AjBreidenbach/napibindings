import ../napi, macros

proc fibonacci(n: int): int =
  if n < 1: 1 else: fibonacci(n-1) + fibonacci(n-2)
init proc(exports: Module) =
  fn(1, fib):
    % fibonacci(args[0].getInt)

  #[exports.register("hello", %*{
      "some_property": ["some value", "value", "other value", undefined(), null()],
      "fib": fib
  })

  exports.registerFn(5, "goodbye"):
    % "fuck"
  ]#
  exports.register("fib", fib)
