### low level bindings ###
import macros

type napi_env = pointer
type napi_value = pointer
type napi_callback_info = pointer
type napi_callback = proc(env: napi_env, info: napi_callback_info): napi_value {.cdecl.}
type napi_property_attributes = int
type napi_property_descriptor {.importc: "napi_property_descriptor", header:"<node_api.h>".} = object
  utf8name: cstring
  name, value: napi_value
  attributes: napi_property_attributes
  `method`, getter, setter: napi_callback
  data: pointer

type JsObject = ref object
  val: napi_value
  env: napi_env
  descriptors: seq[napi_property_descriptor]

proc newJsObject(val: napi_value, env: napi_env): JsObject =
  JsObject(val: val, env: env, descriptors: @[])

#proc napi_create_array

proc napi_define_properties(env: napi_env, val: napi_value, property_count: csize, properties: ptr napi_property_descriptor) {.importc, header:"<node_api.h>".}

var napi_default {.importc, header:"<node_api.h>".}: napi_property_attributes



### low level bindings ###


### high level bindings ###

proc create(env: napi_env, n: int32): napi_value =
  proc napi_create_int32(env: napi_env, n: cint, val: ptr napi_value): int {.importc, header:"<node_api.h>".}
  discard napi_create_int32(env, n, addr result)

proc create(env: napi_env, n: int64): napi_value =
  proc napi_create_int64(env: napi_env, n: int64, val: ptr napi_value): int {.importc, header:"<node_api.h>".}
  discard napi_create_int64(env, n, addr result)

proc create(env: napi_env, n: uint32): napi_value =
  proc napi_create_uint32(env: napi_env, n: uint32, val: ptr napi_value): int {.importc, header:"<node_api.h>".}
  discard napi_create_uint32(env, n, addr result)

proc create(env: napi_env, n: uint64): napi_value =
  proc napi_create_uint64(env: napi_env, n: uint64, val: ptr napi_value): int {.importc, header:"<node_api.h>".}
  discard napi_create_uint64(env, n, addr result)

proc create(env: napi_env, n: float64): napi_value =
  proc napi_create_double(env: napi_env, n: float64, val: ptr napi_value): int {.importc, header:"<node_api.h>".}
  discard napi_create_double(env, n, addr result)

proc create(env: napi_env, s: string): napi_value =
  proc napi_create_string_utf8(env: napi_env, str: cstring, length: csize, val: ptr napi_value): int {.importc, header:"<node_api.h>".}
  discard napi_create_string_utf8(env, s, s.len, addr result)

proc create(env: napi_env, fname: string, cb: napi_callback): napi_value =
  proc napi_create_function(env: napi_env, utf8name: cstring, length: csize, cb: napi_callback, data: pointer, res: napi_value): int {.importc, nodecl.}
  discard napi_create_function(env, fname, fname.len, cb, nil, addr result)


proc registerBase(obj: JsObject, name: string, value: napi_value, attr: int) =
  obj.descriptors.add(
    napi_property_descriptor(
      utf8name: name,
      value: value,
      attributes: napi_default
    )
  )

proc register[T](obj: JsObject, name: string, value: T, attr: int = 0) =
  obj.registerBase(name, create(obj.env, value), attr)

proc registerFn(obj: JsObject, name: string, cb: napi_callback) =
  obj.registerBase(name, create(obj.env, name, cb), 0)

proc defineProperties(obj: JsObject) =
  type DescriptorArray {.unchecked.} = array[0..0, napi_property_descriptor]

  var 
    descriptors = cast[ptr DescriptorArray](alloc(sizeof(napi_property_descriptor) * obj.descriptors.len))
    offset = 0

  for descriptor in obj.descriptors:
    descriptors[][offset] = obj.descriptors[offset]
    offset += 1

  napi_define_properties(obj.env, obj.val, obj.descriptors.len, cast[ptr napi_property_descriptor](descriptors))


### high level bindings ###


proc NimMain{.importc.}

macro init(initHook: proc(exports: JsObject)): typed =
  var cinit = newProc(
    name = ident("cinit"),
    params = [ident("napi_value") , newIdentDefs(ident("env"), ident("napi_env")), newIdentDefs(ident("exportsPtr"), ident("napi_value"))],
    body = newStmtList(
      newCall("NimMain"),
      newVarStmt(ident("exports"), newCall("newJsObject", [ident("exportsPtr"), ident("env")])),
      newCall(initHook, ident("exports")),
      newCall("defineProperties", ident("exports")),
      newNimNode(nnkReturnStmt).add(ident("exportsPtr"))
    )
  )
  cinit.addPragma(ident("exportc"))
  var emit = newNimNode(nnkPragma)
  emit.add(newColonExpr(ident("emit"), newStrLitNode("NAPI_MODULE(NODE_GYP_MODULE_NAME, cinit)")))
  result = newStmtList(
    cinit,
    emit
  )

init proc(exports: JsObject) =
  exports.register("hello", "hello world")
