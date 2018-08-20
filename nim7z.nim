import nim7z/svnz, nim7z/svnzAlloc, nim7z/svnzCrc, nim7z/svnzFile, nim7z/svnzTypes

import os, ospaths, sequtils, strutils

template SzBitArray_Check(p, i: untyped): untyped =
  ((cast[ptr UncheckedArray[int8]](p))[(i) shr 3] and (0x80 shr ((i) and 7)))

template SzArEx_IsDir(p, i: untyped): untyped =
  SzBitArray_Check(p.IsDirs, i)

type
  SvnzFile* = ref SvnzFileObj
  SvnzFileObj = object
    filename: string
    archiveStream: CFileInStream
    lookStream: CLookToRead2
    db: CSzArEx

  SvnzError* = object of Exception

var
  g_Alloc = ISzAlloc(Alloc: SzAlloc, Free: SzFree)
  allocImp = g_Alloc
  allocTempImp = g_Alloc
  kInputBufSize = 1 shl 18

  res: SRes = SZ_OK

  temp: ptr UInt16
  tempSize = 0

proc checkError() =
  if res != SZ_OK:
    if res == SZ_ERROR_UNSUPPORTED:
      raise newException(SvnzError, "Decoder doesn't support this archive")
    elif res == SZ_ERROR_MEM:
      raise newException(SvnzError, "Can not allocate memory")
    elif res == SZ_ERROR_CRC:
      raise newException(SvnzError, "CRC error")
    else:
      raise newException(SvnzError, "Value = " & $res)

proc new7zFile*(fname: string): SvnzFile =
  ## Opens a .7z file for reading.
  result = SvnzFile(filename: fname)

proc loadDataStream(svnz: SvnzFile) =
  if InFile_Open(addr svnz.archiveStream.file, svnz.filename) != 0:
    raise newException(SvnzError, "Failed to load file: " & svnz.filename)

  FileInStream_CreateVTable(addr svnz.archiveStream)
  LookToRead2_CreateVTable(addr svnz.lookStream, False)

  svnz.lookStream.buf = cast[ptr Byte](allocImp.Alloc(addr allocImp, kInputBufSize))
  if svnz.lookStream.buf == nil:
    res = SZ_ERROR_MEM
  else:
    svnz.lookStream.bufSize = kInputBufSize
    svnz.lookStream.realStream = addr svnz.archiveStream.vt
    svnz.lookStream.pos = 0
    svnz.lookStream.size = 0

  CrcGenerateTable();

  SzArEx_Init(addr svnz.db)

  if res == SZ_OK:
    res = SzArEx_Open(addr svnz.db, addr svnz.lookStream.vt, addr allocImp, addr allocTempImp)

  checkError()

iterator walk(svnz: SvnzFile): tuple[filename: string, isdir: int, contents: ptr Byte, size: int] =
  var
    blockIndex = 0xFFFFFFFF.uint32
    outBuffer: ptr Byte = nil
    outBufferSize = 0

  for i in 0 ..< svnz.db.NumFiles:
    var
      offset = 0
      outSizeProcessed = 0
      length = SzArEx_GetFileNameUtf16(addr svnz.db, i.csize, nil)
      isDir = SzArEx_IsDir(svnz.db, i.int)

    if length > tempSize:
      SzFree(nil, temp)
      tempSize = length
      temp = cast[ptr UInt16](SzAlloc(nil, tempSize * sizeof(UInt16)))
      if temp == nil:
        res = SZ_ERROR_MEM
        break

    discard SzArEx_GetFileNameUtf16(addr svnz.db, i.csize, temp)

    if isDir == 0:
      res = SzArEx_Extract(addr svnz.db, addr svnz.lookStream.vt, i.UInt32, addr blockIndex,
        addr outBuffer, addr outBufferSize, addr offset, addr outSizeProcessed,
        addr allocImp, addr allocTempImp)

      if res != SZ_OK:
        break

    yield ($cast[WideCString](temp), isDir, cast[ptr Byte](cast[int](outBuffer)+offset), outSizeProcessed)

  checkError()

proc `=destroy`(svnz: var SvnzFileObj) =
  SzArEx_Free(addr svnz.db, addr allocImp)
  allocImp.Free(addr allocImp, svnz.lookStream.buf)

  discard File_Close(addr svnz.archiveStream.file)

proc extract*(svnz: SvnzFile, directory: string, skipOuterDirs=false, tempDir: string = "") =
  ## Extracts the files stored in the opened ``SvnzFile`` into the specified
  ## ``directory``.
  ##
  ## Options
  ## -------
  ##
  ## ``skipOuterDirs`` - If ``true``, the archive's directory structure is not
  ## recreated; all files are deposited in the extraction directory. Similar to
  ## ``unzip``'s ``-j`` flag.

  # Create a temporary directory for us to extract into. This allows us to
  # implement the ``skipOuterDirs`` feature and ensures that no files are
  # extracted into the specified directory if the extraction fails mid-way.
  var tempDir = tempDir
  if tempDir.len() == 0:
    tempDir = getTempDir() / "nim7z-" & svnz.filename.extractFilename()
  removeDir(tempDir)
  createDir(tempDir)

  svnz.loadDataStream()

  for file, isDir, data, size in svnz.walk():
    if isDir == 0:
      let fp = (tempDir / (if not skipOuterDirs: file else: file.extractFilename())).open(fmWrite)
      let arr = cast[ptr UncheckedArray[char]](data)
      for i in 0 ..< size:
        write(fp, arr[i])
      fp.close()
    else:
      if not skipOuterDirs:
        createDir(tempDir / file)

  # Determine which directory to copy.
  var srcDir = tempDir
  let contents = toSeq(walkDir(srcDir))
  if contents.len == 1 and skipOuterDirs:
    # Skip the outer directory.
    srcDir = contents[0][1]

  # Finally copy the directory to what the user specified.
  copyDir(srcDir, directory)
  removeDir(tempDir)

proc extract*(svnzf, directory: string, skipOuterDirs=false, tempDir: string = "") =
  ## Extracts the files stored in the file name specified, to the directory specified.
  let svnz = new7zFile(svnzf)
  extract(svnz, directory, skipOuterDirs, tempDir)
