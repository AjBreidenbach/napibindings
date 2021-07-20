version  = "0.0"
author  = "andrew breidenbach"
description  = "bindings for node api"
license  = "MIT"
srcDir = "src"
skipDirs  = @["test", ".git"]
bin  = @["napibuild"]

requires "https://github.com/docopt/docopt.nim#master"

task test,"test":
  withDir "test":
    exec "yarn install --ignore-scripts"
  exec "nim c -r src/napibuild.nim test/main.nim"
  exec "node test/index.js"