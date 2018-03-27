### low level bindings ###
import macros

template assess*(status: int) =
  assert(status == 0, "[napi_status: " & $ NapiStatus(status) & ']')

type napi_env* = pointer

var `env$`*: napi_env = nil

type napi_value* = pointer
type napi_callback_info* = pointer
type napi_callback* = proc(environment: napi_env, info: napi_callback_info): napi_value {.cdecl.}
type napi_property_attributes* = int
type napi_property_descriptor* {.importc: "napi_property_descriptor", header:"<node_api.h>".} = object
  utf8name: cstring
  name, value: napi_value
  attributes: napi_property_attributes
  `method`, getter, setter: napi_callback
  data: pointer

type NapiKind* {.importc: "napi_valuetype".}= enum
  napi_undefined
  napi_null
  napi_boolean
  napi_number
  napi_string
  napi_symbol
  napi_object
  napi_function
  napi_external
  napi_valuetype

type NapiStatus* {.importc: "napi_status".} = enum
  napi_ok
  napi_invalid_arg
  napi_object_expected
  napi_string_expected
  napi_name_expected
  napi_function_expected
  napi_number_expected
  napi_boolean_expected
  napi_array_expected
  napi_generic_failure
  napi_pending_exception
  napi_cancelled
  napi_status_last

type Module* = ref object
  val*: napi_value
  env*: napi_env
  descriptors: seq[napi_property_descriptor]

proc getInt64*(n: napi_value): int64 =
  proc napi_get_value_int64(e: napi_env, v: napi_value, res: ptr int64): int{.header: "<node_api.h>".}
  assess napi_get_value_int64(`env$`, n, addr result)

proc getInt32*(n: napi_value): int32 =
  proc napi_get_value_int32(e: napi_env, v: napi_value, res: ptr int32): int {.header: "<node_api.h>".}
  assess napi_get_value_int32(`env$`, n, addr result)

template getInt*(n: napi_value): int =
  when sizeof(int) == 8:
    int(n.getInt64())
  else:
    int(n.getInt32())

proc getStr*(n: napi_value, bufsize: int = 40): string =
  proc napi_get_value_string_utf8(e: napi_env, v: napi_value, buf: cstring, bufsize: csize, res: ptr csize): int {.header: "<node_api.h>".}
  var 
    buf = cast[cstring](alloc(bufsize))
    res: csize

  assess napi_get_value_string_utf8(`env$`, n, buf, bufsize, addr res)
  return  ($buf)[0..res]


proc newNodeValue*(val: napi_value, env: napi_env): Module =
  Module(val: val, env: env, descriptors: @[])

proc kind*(env: napi_env, val: napi_value): NapiKind =
  proc napi_typeof (e: napi_env, v: napi_value, res: ptr NapiKind): int{.header: "<node_api.h>".}
  assess ( napi_typeof(env, val, addr result) )

proc kind*(val: Module): NapiKind =
  kind(val.env, val.val)

proc napi_define_properties(env: napi_env, val: napi_value, property_count: csize, properties: ptr napi_property_descriptor) {.header:"<node_api.h>".}
proc napi_get_cb_info*(env: napi_env, cbinfo: napi_callback_info, argc: ptr csize, argv: pointer, this: napi_value, data: pointer = nil): int {.header:"<node_api.h>".}

var napi_default {.header:"<node_api.h>".}: napi_property_attributes

### low level bindings ###


### high level bindings ###

proc create(env: napi_env, n: int32): napi_value =
  proc napi_create_int32(env: napi_env, n: cint, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_int32(env, n, addr result) )

proc create*(env: napi_env, n: int64): napi_value =
  proc napi_create_int64(env: napi_env, n: int64, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_int64(env, n, addr result) )

proc create(env: napi_env, n: uint32): napi_value =
  proc napi_create_uint32(env: napi_env, n: uint32, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_uint32(env, n, addr result) )

proc create(env: napi_env, n: uint64): napi_value =
  proc napi_create_uint64(env: napi_env, n: uint64, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_uint64(env, n, addr result) )

proc create(env: napi_env, n: float64): napi_value =
  proc napi_create_double(env: napi_env, n: float64, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_double(env, n, addr result) )

proc create*(env: napi_env, s: string): napi_value =
  proc napi_create_string_utf8(env: napi_env, str: cstring, length: csize, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_string_utf8(env, s, s.len, addr result) )

proc create*(env: napi_env, p: openarray[(string, napi_value)]): napi_value =
  proc napi_create_object(env: napi_env, res: ptr napi_value): int {.header:"<node_api.h>".}
  proc napi_set_named_property(env: napi_env, obj: napi_value, utf8name: cstring, value: napi_value): int {.header:"<node_api.h>".}
  assess napi_create_object(env, addr result)
  for name, val in items(p):
    assess napi_set_named_property(env, result, name, val)


proc create*(env: napi_env, a: openarray[napi_value]): napi_value =
  proc napi_create_array_with_length(e: napi_env, length: csize, res: ptr napi_value): int {.header:"<node_api.h>".}
  proc napi_set_element(e: napi_env, o: napi_value, index: csize, value: napi_value): int {.header:"<node_api.h>".}
  assess( napi_create_array_with_length(env, a.len, addr result) )
  var counter = 0
  for elem in a:
    assess napi_set_element(env, result, counter, a[counter])
    counter += 1

proc create*[T: int | uint | string](env: napi_env, a: openarray[T]): napi_value =
  var elements = newSeq[napi_value]()
  for elem in a: elements.add(env.create(elem))
  env.create(elements)


proc create*[T: int | uint | string](env: napi_env, a: openarray[(string, T)]): napi_value =
  var properties = newSeq[(string, napi_value)]()
  for prop in a: properties.add((prop[0], create(prop[1])))
  env.create(a)

proc create*(env: napi_env, v: napi_value): napi_value = v

proc create*[T](n: Module, t: T): napi_value =
  n.env.create(t)

proc hasOwnProperty*(env: napi_env, obj: napi_value, key: string): bool =
    assert kind(env, obj) == napi_object, "value is not an object"
    proc napi_has_own_property(env: napi_env, obj: napi_value, key: napi_value, res: ptr bool): int {.header:"<node_api.h>".}
    assess napi_has_own_property(env, obj, env.create(key), addr result)


proc getProperty*(env: napi_env, obj: napi_value, key: string): napi_value =
  assert hasOwnProperty(env, obj, key), "property not contained"
  proc napi_get_named_property(env: napi_env, obj: napi_value, name: cstring, res: ptr napi_value): int {.header:"<node_api.h>".}
  assess napi_get_named_property(env, obj, key, addr result)



proc createFn*(env: napi_env, fname: string, cb: napi_callback): napi_value =
  proc napi_create_function(env: napi_env, utf8name: cstring, length: csize, cb: napi_callback, data: pointer, res: napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_function(env, fname, fname.len, cb, nil, addr result) )



proc registerBase(obj: Module, name: string, value: napi_value, attr: int) =
  obj.descriptors.add(
    napi_property_descriptor(
      utf8name: name,
      value: value,
      attributes: napi_default
    )
  )

proc register*[T: int | uint | string | napi_value](obj: Module, name: string, value: T, attr: int = 0) =
  obj.registerBase(name, create(obj.env, value), attr)

proc register*[T: int | uint | string | napi_value](obj: Module, name: string, values: openarray[T], attr: int = 0) =
  var elements =  newSeq[napi_value]()
  for v in values: elements.add(obj.create(v))

  obj.registerBase(name, create(obj.env, elements), attr)

proc register*[T: int | uint | string | napi_value](obj: Module, name: string, values: openarray[(string, T)], attr: int = 0) =
  var properties = newSeq[(string, napi_value)]()
  for v in values: properties.add((v[0], obj.create(v[1])))

  obj.registerBase(name, create(obj.env, properties), attr)

proc register*(obj: Module, name: string, cb: napi_callback) =
  obj.registerBase(name, createFn(obj.env, name, cb), 0)


template `%`*[T](t: T): napi_value =
  `env$`.create(t)

macro getIdentStr*(n: untyped): string = $ident(n)

template fn*(paramCt: int, name, cushy: untyped): untyped {.dirty.} =
  var name {.inject.}: napi_value
  block:
    proc wrapper(environment: napi_env, info: napi_callback_info): napi_value {.cdecl.} =
      var 
        `argv$`: napi_value
        argc: csize = paramCt
        this: napi_value
        args = newSeq[napi_value]()
      `env$` = environment
      assess napi_get_cb_info(environment, info, addr argc, addr `argv$`, addr this)
      var `argsarray$` = cast[ptr UncheckedArray[napi_value]](addr `argv$`)
      for i in 0..<argc:
        args.add(`argsarray$`[][i])
      cushy

    name = createFn(`env$`, getIdentStr(name), wrapper)


template registerFn*(exports: Module, paramCt = 10, name: string, cushy: untyped): untyped {.dirty.}=
  block:
    proc wrapper(environment: napi_env, info: napi_callback_info): napi_value {.cdecl.} =
      var 
        `argv$`: napi_value
        argc: csize = paramCt
        this: napi_value
        args = newSeq[napi_value]()

      `env$` = environment

      assess napi_get_cb_info(environment, info, addr argc, addr `argv$`, addr this)
      var
        `argsarray$` = cast[ptr UncheckedArray[napi_value]](addr `argv$`)
      for i in 0..<argc:
        args.add(`argsarray$`[][i])
      cushy
    exports.register(name, wrapper)

proc defineProperties*(obj: Module) =
  type DescriptorArray {.unchecked.} = array[0..0, napi_property_descriptor]

  var 
    descriptors = cast[ptr DescriptorArray](alloc(sizeof(napi_property_descriptor) * obj.descriptors.len))
    offset = 0

  for descriptor in obj.descriptors:
    descriptors[][offset] = obj.descriptors[offset]
    offset += 1

  napi_define_properties(obj.env, obj.val, obj.descriptors.len, cast[ptr napi_property_descriptor](descriptors))


### high level bindings ###

macro init*(initHook: proc(exports: Module)): typed =
  var nimmain = newProc(ident("NimMain"))
  nimmain.addPragma(ident("importc"))
  var cinit = newProc(
    name = ident("cinit"),
    params = [ident("napi_value") , newIdentDefs(ident("environment"), ident("napi_env")), newIdentDefs(ident("exportsPtr"), ident("napi_value"))],
    body = newStmtList(
      nimmain,
      newCall("NimMain"),
      newVarStmt(ident("exports"), newCall("newNodeValue", [ident("exportsPtr"), ident("environment")])),
      newAssignment(ident("env$"), ident("environment")),
      newCall(initHook, ident("exports")),
      newCall("defineProperties", ident("exports")),
      newNimNode(nnkReturnStmt).add(ident("exportsPtr"))
    )
  )
  cinit.addPragma(ident("exportc"))
  var emit = newNimNode(nnkPragma).add(newColonExpr(ident("emit"), newStrLitNode("NAPI_MODULE(NODE_GYP_MODULE_NAME, cinit)")))
  result = newStmtList(
    cinit,
    emit
  )
