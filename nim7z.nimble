# Package

version       = "0.1.5"
author        = "genotrance"
description   = "7z extraction for Nim"
license       = "MIT"

skipDirs = @["tests"]

# Dependencies

requires "nimgen >= 0.4.0"

var
  name = "nim7z"
  cmd = when defined(Windows): "cmd /c " else: ""

mkDir(name)

task setup, "Checkout and generate":
  if gorgeEx(cmd & "nimgen").exitCode != 0:
    withDir(".."):
      exec "nimble install nimgen -y"
  exec cmd & "nimgen " & name & ".cfg"

before install:
  setupTask()

task test, "Run tests":
  exec "nim c -r tests/t" & name & ".nim"
