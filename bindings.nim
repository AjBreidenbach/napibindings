### low level bindings ###
import macros

template assess*(status: int) =
  assert(status == 0, "[napi_status: " & $ NapiStatus(status) & ']')

type napi_env* = pointer
type napi_value* = pointer
type napi_callback_info* = pointer
type napi_callback* = proc(env: napi_env, info: napi_callback_info): napi_value {.cdecl.}
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

type NapiNode* = ref object
  val*: napi_value
  env: napi_env
  descriptors: seq[napi_property_descriptor]

proc getInt*(n: NapiNode): int =
  proc napi_get_value_int64(e: napi_env, v: napi_value, res: ptr int): int {.header: "<node_api.h>".}
  assess napi_get_value_int64(n.env, n.val, addr result)

proc getStr*(n: NapiNode, bufsize: int = 40): string =
  proc napi_get_value_string_utf8(e: napi_env, v: napi_value, buf: cstring, bufsize: csize, res: ptr csize): int {.header: "<node_api.h>".}
  var 
    buf = cast[cstring](alloc(bufsize))
    res: csize

  assess napi_get_value_string_utf8(n.env, n.val, buf, bufsize, addr res)
  return  ($buf)[0..res]


proc newNodeValue*(val: napi_value, env: napi_env): NapiNode =
  NapiNode(val: val, env: env, descriptors: @[])


proc kind*(val: NapiNode): NapiKind =
  proc napi_typeof (e: napi_env, v: napi_value, res: ptr NapiKind): int{.header: "<node_api.h>".}
  assess ( napi_typeof(val.env, val.val, addr result) )

#proc napi_create_array

proc napi_define_properties(env: napi_env, val: napi_value, property_count: csize, properties: ptr napi_property_descriptor) {.header:"<node_api.h>".}
proc napi_get_cb_info*(env: napi_env, cbinfo: napi_callback_info, argc: ptr csize, argv: pointer, this: napi_value, data: pointer = nil): int {.header:"<node_api.h>".}

var napi_default {.header:"<node_api.h>".}: napi_property_attributes

### low level bindings ###


### high level bindings ###

proc create(env: napi_env, n: int32): napi_value =
  proc napi_create_int32(env: napi_env, n: cint, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_int32(env, n, addr result) )

proc create(env: napi_env, n: int64): napi_value =
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

proc create(env: napi_env, s: string): napi_value =
  proc napi_create_string_utf8(env: napi_env, str: cstring, length: csize, val: ptr napi_value): int {.header:"<node_api.h>".}
  assess ( napi_create_string_utf8(env, s, s.len, addr result) )

proc createFn(env: napi_env, fname: string, cb: napi_callback): napi_value =
  proc napi_create_function(env: napi_env, utf8name: cstring, length: csize, cb: napi_callback, data: pointer, res: napi_value): int {.importc, nodecl.}
  assess ( napi_create_function(env, fname, fname.len, cb, nil, addr result) )


proc registerBase(obj: NapiNode, name: string, value: napi_value, attr: int) =
  obj.descriptors.add(
    napi_property_descriptor(
      utf8name: name,
      value: value,
      attributes: napi_default
    )
  )

proc register*[T: int | uint | string](obj: NapiNode, name: string, value: T, attr: int = 0) =
  obj.registerBase(name, create(obj.env, value), attr)

proc register*(obj: NapiNode, name: string, cb: napi_callback) =
  obj.registerBase(name, createFn(obj.env, name, cb), 0)

template registerFn*(exports: NapiNode, name: string, paramCt = 10, cushy: untyped): untyped {.dirty.}=
  block:
    proc wrapper(e: napi_env, i: napi_callback_info): napi_value {.cdecl.} =
      var 
        `argv$`: napi_value
        argc: csize = paramCt
        `this$`: napi_value
        args = newSeq[NapiNode]()
      assess napi_get_cb_info(e, i, addr argc, addr `argv$`, addr `this$`)
      var
        `argsarray$` = cast[ptr UncheckedArray[napi_value]](addr `argv$`)
        this = newNodeValue(`this$`, e)
      for i in 0..<argc:
        args.add(newNodeValue(`argsarray$`[][i], e))
      cushy
    exports.register(name, wrapper)



proc defineProperties*(obj: NapiNode) =
  type DescriptorArray {.unchecked.} = array[0..0, napi_property_descriptor]

  var 
    descriptors = cast[ptr DescriptorArray](alloc(sizeof(napi_property_descriptor) * obj.descriptors.len))
    offset = 0

  for descriptor in obj.descriptors:
    descriptors[][offset] = obj.descriptors[offset]
    offset += 1

  napi_define_properties(obj.env, obj.val, obj.descriptors.len, cast[ptr napi_property_descriptor](descriptors))


### high level bindings ###


macro init*(initHook: proc(exports: NapiNode)): typed =
  var nimmain = newProc(ident("NimMain"))
  nimmain.addPragma(ident("importc"))
  var cinit = newProc(
    name = ident("cinit"),
    params = [ident("napi_value") , newIdentDefs(ident("env"), ident("napi_env")), newIdentDefs(ident("exportsPtr"), ident("napi_value"))],
    body = newStmtList(
      nimmain,
      newCall("NimMain"),
      newVarStmt(ident("exports"), newCall("newNodeValue", [ident("exportsPtr"), ident("env")])),
      newCall(initHook, ident("exports")),
      newCall("defineProperties", ident("exports")),
      newNimNode(nnkReturnStmt).add(ident("exportsPtr"))
    )
  )
  cinit.addPragma(ident("exportc"))
  var emit = newNimNode(nnkPragma).add(newColonExpr(ident("emit"), newStrLitNode("NAPI_MODULE(NODE_GYP_MODULE_NAME, cinit)")))
  var header = newNimNode(nnkPragma).add(newColonExpr(ident("emit"), newStrLitNode( """/*INCLUDESECTION*/ #include <node_api.h> """)))
  result = newStmtList(
    cinit,
    emit,
    header
  )
