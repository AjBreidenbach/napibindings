### use projectfile.json for linking option
##
import json, docopt, os


const doc = """
NodeBuild.

Usage:
  nodebuild debug <projectfile> <nimcache> [options]
  nodebuild release <projectfile> <nimcache> [options]

  -c  compile projectfile
  -l  link into .node file
"""



let args = docopt(doc)

if args["-c"]:
  discard execShellCmd "nim c -c --compileOnly --noMain " & $args["<projectfile>"]

var target = %*
  { "target_name": "target" }

var nimbase = (findExe("nim") /../ "" /../ "lib")


target["include_dirs"] = %[ nimbase ]
target["cflags"] = %["-w"]
if args["release"]: target["cflags"].add(%"-O3")
target["linkflags"] = %["-ldl"]


var compiledpf = ($args["<projectfile>"]).changeFileExt(".c")

target["sources"] = %[$args["<nimcache>"] / compiledpf ]

for filekind, srcfile in walkdir(getCurrentDir() / $args["<nimcache>"]):
  if srcfile.extractFilename != compiledpf and srcfile.splitFile.ext == ".c":
    target["sources"].add %($args["<nimcache>"] / srcfile.extractFilename)


var gyp = %*
 {
  "targets": [ target ]
 }

writeFile("binding.gyp", gyp.pretty)


if args["-l"]:
  discard execShellCmd "node-gyp rebuild"
