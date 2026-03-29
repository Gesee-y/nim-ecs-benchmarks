import osproc, os, strutils, unicode, sequtils, tables

let metrics = @[
  "create entity",
  "delete entity",
  "add component",
  "remove component",
  "add remove component",
  "iteration",
  "read",
  "write"
]

let firstColumnWidth = 20
let timeColumnWidth = 10
let memColumnWidth = 9

var comparisons = Table[string, Table[string, string]]()
var suiteOrder: seq[string] = @[]

proc alignUnicode(s: string, width: int, padding = ' '): string =
  let visLen = s.runeLen
  if visLen >= width:
    s
  else:
    spaces(width - visLen) & s

proc border(left: string, right: string, thickJoin: string, thinJoin: string, columnCount: int): string =
  let firstColumn = left & "═" & "═".repeat(firstColumnWidth) & "═" & thickJoin & "═"
  let column = "═".repeat(timeColumnWidth) & "═" & thinJoin & "═" & "═".repeat(memColumnWidth + 1)
  let regularColumn = column & thickJoin
  let lastColumn = column & right
  firstColumn & regularColumn.repeat(columnCount - 1) & lastColumn

proc header(infos: seq[string]): string =
  result = "║ " & " ".repeat(firstColumnWidth) & " ║ "
  let width = timeColumnWidth + memColumnWidth + 4

  for info in infos:
    let name = if info.runeLen >= width: info.runeSubStr(0, width - 1) else: info
    result &= name.center(width) & "║"

for metric in metrics:
  comparisons[metric] = Table[string, string]()

for src in walkFiles(getCurrentDir() / "src" / "*_bench.nim"):
  if execCmd("nim c -r -d:danger -o:bench_runner " & src) != 0:
    echo "!!! Compilation failed for ", src
    quit(1)

for csvFile in walkFiles("*.csv"):
  let lines = readFile(csvFile).splitLines()
  let bench = lines[0].split(',')[0]
  suiteOrder.add(bench)

  for line in lines[1..^1]:
    if line.len == 0:
      continue

    let parts = line.split(',')
    let metric = parts[0]

    if metric in comparisons:
      let results = parts[1].align(10) & " │ " & parts[2].align(9)
      comparisons[metric][bench] = results

echo ""
echo border("╔", "╗", "╦", "═", suiteOrder.len)
echo header(suiteOrder)
let timeMem = "time   ".align(timeColumnWidth) & "   " & "mem   ".align(memColumnWidth) 
echo header(sequtils.repeat(timeMem, suiteOrder.len))
echo border("╠", "╣", "╬", "╤", suiteOrder.len)

for metric in metrics:
  var row = "║ " & metric.alignLeft(firstColumnWidth) & " ║ "
  for suite in suiteOrder:
    if suite in comparisons[metric]:
      row &= comparisons[metric][suite] & " ║"
    else:
      row &= "     -     │     -     ║"
  echo row

echo border("╚", "╝", "╩", "╧", suiteOrder.len)
