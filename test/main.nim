import napibindings, sequtils

init proc(exports: Module) =
  exports.register("hello", "hello world")

  exports.registerFn(10, "addNums"):
    %(args.mapIt(it.getInt).foldl(a + b))

  exports.registerFn(10, "createArray"):
    result = % [5]
    for n in 0..<args.len:
      result[n] = args[n]
  
  exports.registerFn(3, "getOrDefault"):
    ##``args[0]`` : array
    ##``args[1]`` : index
    ##``args[2]`` : default
    args[0].getElement(args[1].getInt, args[2])

