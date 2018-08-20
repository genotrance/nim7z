import nim7z

import os, strutils

removeDir("tempdir")

let svnzf = new7zFile("tests/tests.7z")
extract(svnzf, "tempdir")

assert fileExists("tempdir"/"nimcache"/"nim7z_test7z.c")

while dirExists("tempdir"):
  try:
    removeDir("tempdir")
    sleep(1000)
  except:
    discard

extract(svnzf, "tempdir", true)

assert fileExists("tempdir"/"nim7z_test7z.c")

removeDir("tempdir")

try:
  extract("nim7z.nimble", "tempdir")
except SvnzError:
  if "17" notin getCurrentExceptionMsg():
    quit(1)

