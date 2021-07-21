import json, docopt, os, osproc

const ExplicitSourcePath {.strdefine.} = os.parentDir(os.parentDir(os.getCurrentCompilerExe()))
const LibPath = ExplicitSourcePath / "lib"
const doc = """
NodeBuild.
Usage:
  napibuild <projectfile> [options]

Options:
  -C          do not recompile projectfile
  -r          release build
"""

let args = docopt(doc)

var
  projectfile = $args["<projectfile>"]
  project = splitFile(projectfile)
  nimbase = LibPath
  nimcache = project.dir / "nimcache" #$args["<nimcache>"]
  target = %* {"target_name": project.name}
  gyp = %* {"targets": [target]}


if not args["-C"]:
  var releaseFlag = if args["-r"]: "-d:release " else: "--embedsrc "
  let r = execCmdEx "nim c --nimcache:" & nimcache & " " & releaseFlag & "--compileOnly --noMain " & projectfile
  doAssert r.exitCode == 0, r.output


target["include_dirs"] = %[nimbase]
target["cflags"] = %["-w"]
if args["-r"]:
  target["cflags"].add(%"-O3")
  target["cflags"].add(%"-fno-strict-aliasing")
target["linkflags"] = %["-ldl"]

target["sources"] = %[]
for targetobj in parsejson(readfile(nimcache / (project.name & ".json")))["link"]:
  target["sources"].add( % ("nimcache" / targetobj.getstr.splitFile.name))

writeFile(project.dir / "binding.gyp", gyp.pretty)


var gypflags = "--directory=" & project.dir
if not args["-r"]: gypflags.add(" --debug")

let gypRebuild = execCmdEx "node-gyp rebuild " & gypflags
doAssert gypRebuild.exitCode == 0, gypRebuild.output
