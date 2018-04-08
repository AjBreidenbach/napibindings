# NapiBindings
Bindings between Nim and N-API

## Getting started	
These instructions will help you get up and running.  Keep in mind this project is still in its infancy and may be incomplete or subject to change.

If you don't yet have Nim installed, please visit https://nim-lang.org/install.html

### Prerequisites
First of all, you will need to have Node installed with a version number no less than `8.0`.  N-API was introduced in this version and remains experimental.
`napibuild` is a program distributed as a binary in this project which attempts to automate the process of creating `.node` addons from a nim project file.


`napibuild` depends on an npm package called `node-gyp` which can be installed via 
```bash
npm install -g node-gyp
```

Consequently, `node-gyp` requires `python 2.x`, while version `2.7` is recommended.  `node-gyp` has a few other OS-specific build essentials which are detailed [here](https://www.npmjs.com/package/node-gyp), but will likely work out-of-the-box on most systems.


### Installing
To install this library and `napibuild`
```bash
git clone https://github.com/AjBreidenbach/napibindings.git
cd napibindings
nimble install
```

Enter `y` and you're finished

To run all tests
```bash
cd test/
npm install
napibuild main.nim
node index.js
cd ../
```
To view the documentation
```bash
nim doc napibindings.nim && google-chrome napibindings.html > /dev/null &

```



### Creating a new simple project
Start by running `npm init` and entering information as prompted

`bindings` is a useful package for loading native addons, it can be installed via `npm install --save bindings`

Loading addons compiled by `node-gyp` then becomes as simple as
```JavaScript
const addon = require('bindings')('myNimProjectfile')
```
Where the original Nim file `myNimProjectfile.nim` was compiled via
```bash
napibuild myNimProjectfile.nim
```
In `myNimProjectfile.nim`, the node module can be initialized by the following
```nim
import napibindings
init proc(exports: Module) =
	exports.register("hello", "hello world!")
```

## Features
### napi_value
The basic unit for N-API values is the type `napi_value`.  They are wrapped such that they behave very similarly to the `JsonNode` type from the core Nim json module.  They can be indexed via `[]` and `[]=` and even support the `%` and `%*` marshalling operators.
### register
`register` can be used to add Nim primitives and `napi_value`s to a module's exports.  Their use is rather straightforward.
### fn and registerFn
`fn` and `registerFn` are templates which can be called
```nim
fn(2, myFunction):
	return %(args[0].getInt + args[1].getInt)
```
and  ...

```nim
exports.registerFn(2, "myFunction"):
	return %* {"first": args[0], "second": args[1]}
```
respectively. 

In the case of `fn`, `myFunction` is injected into the caller's scope, whereas `registerFn` would added to `exports` directly.

Both templates expose `args` of type `seq[napi_value]` which are the parameters passed through the JavaScript invocation  and `this` of type `napi_value` which is identical to the JavaScript `this` global variable.  Both templates are also able to return a `napi_value` or `nil` for `undefined`.
### callFunction
`callFunction` can be used as would be expected and has the following declaration
```nim
proc callFunction(fn: napi_value; args: openArray[napi_value] = []; this = %[]): napi_value {..}
```

## Improving these bindings
All contributions are welcome.

The goal of this project is to wrap all of the functionality of N-API as detailed [here](https://nodejs.org/api/n-api.html) in a way that is ergonomic, performant, and idiomatic to Nim.

The entirety of the API can presently be imported in Nim when compiling with `napibuild` via the pragma `header: "<node_api.h>"`  and is not terribly difficult to work with.

In the future, `napibuild` should either be expanded to allow for more build flexibility  and `gyp` functionality or faded out in favor of build tools preferred by the Nim community.
