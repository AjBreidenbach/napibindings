### use projectfile.json for linking option
##
import json, docopt, os, sequtils


const doc = """
NodeBuild.
Usage:
  nodebuild <projectfile> <nimcache> [options]
"""
let args = docopt(doc)

var 
  nimbase = (findExe("nim") /../ "" /../ "lib")
  nimcache = $args["<nimcache>"]
  projectfile = $args["<projectfile>"]
  target = %* { "target_name": "target" }
  gyp = %* { "targets": [target] }



#[if not args["--C"]:
  var releaseFlag = if args["--r"]: " -d:release " else: ""
  discard execShellCmd("nim c -c" & releaseFlag & "--compileOnly --noMain " & projectfile)
  ]#
  
discard execShellCmd("nim c -c --compileOnly --noMain " & projectfile) #



target["include_dirs"] = %[ nimbase ]
target["cflags"] = %["-w"]
#if args["--r"]: target["cflags"].add(%"-O3")
target["linkflags"] = %["-ldl"]


var compiledpf = (projectfile).changeFileExt(".c")

target["sources"] = %[]
for targetobj in parsejson(readfile(nimcache / (projectfile.splitFile.name & ".json")))["link"]:
  target["sources"].add(% (nimcache / targetobj.getstr.splitFile.name & ".c"))


writeFile("binding.gyp", gyp.pretty)


#if not args["--N"]:
  #discard execShellCmd "node-gyp rebuild"
discard execShellCmd "node-gyp rebuild"
