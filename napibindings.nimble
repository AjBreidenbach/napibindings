version  = "0.0"
author  = "andrew breidenbach"
description  = "bindings for node api"
license  = "MIT"
srcDir = "src"
skipDirs  = @["test", ".git"]
bin  = @["napibuild"]

requires "docopt"
import os
task test,"test":
  exec findExe("yarn") & " install --ignore-scripts --cwd test"
  selfExec "c -r " & "src" / "napibuild.nim" & " -r " & "test" / "main.nim"
  exec findExe("node") &  " " & "test" / "index.js"