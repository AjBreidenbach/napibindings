import json, docopt, os, sequtils


const doc = """
NodeBuild.
Usage:
  nodebuild <projectfile> [options]

Options:
  -C          do not recompile projectfile
  -r          release build
"""
let args = docopt(doc)

var 
  projectfile = $args["<projectfile>"]
  project = splitFile(projectfile)
  nimbase = (findExe("nim") /../ "" /../ "lib")
  nimcache = project.dir / "nimcache"#$args["<nimcache>"]
  target = %* { "target_name": project.name }
  gyp = %* { "targets": [target] }


template assess(name: string, cmd: string) =
  var status = execShellCmd(cmd)
  doAssert status == 0, "exit with nonzero status: " & $status & " for command " & cmd


if not args["-C"]:
  var releaseFlag = if args["-r"]: "-d:release " else: "--embedsrc "
  assess "nim c", "nim c --nimcache:" & nimcache & " " & releaseFlag & "--compileOnly --noMain " & projectfile


target["include_dirs"] = %[ nimbase ]
target["cflags"] = %["-w"]
if args["-r"]:
  target["cflags"].add(%"-O3")
  target["cflags"].add(%"-fno-strict-aliasing")
target["linkflags"] = %["-ldl"]


var compiledpf = (projectfile).changeFileExt(".c")

target["sources"] = %[]
for targetobj in parsejson(readfile(nimcache / (project.name & ".json")))["link"]:
  target["sources"].add(% ("nimcache" / targetobj.getstr.splitFile.name))


writeFile(project.dir / "binding.gyp", gyp.pretty)


var gypflags = "--directory=" & project.dir
if not args["-r"]: gypflags.add(" --debug")

assess "node-gyp", "node-gyp rebuild "  & gypflags
