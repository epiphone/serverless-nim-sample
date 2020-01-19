## Overwrite `nim compile` task to optimize binary size.
## Adapted from https://scripter.co/nim-deploying-static-binaries/
from ospaths import splitFile, `/`
from strutils import split, startsWith

proc binOptimize(binFile: string) =
  ## Optimize size of the ``binFile`` binary.
  echo ""
  if findExe("strip") != "":
    echo "Running 'strip -s' .."
    exec "strip -s " & binFile
  if findExe("upx") != "":
    # https://github.com/upx/upx/releases/
    echo "Running 'upx --best' .."
    exec "upx --best " & binFile


task c, "Compile a minified binary":
  let
    numParams = paramCount()
    nimFile = paramStr(numParams)
    (dirName, baseName, _) = splitFile(nimFile)

  var
    binFile = dirName / baseName
    cmd = "compile --opt:size "

  for i in 2..numParams:
    let param = paramStr(i)
    cmd &= " " & param

    if param.startsWith("-o:") or param.startsWith("--output:"):
      binFile = param.split(":")[1]

  echo "Running nim ", cmd
  selfExec cmd

  binOptimize(binFile)

