import osproc, os, strutils, unicode, tables, sets, math

let metrics = @[
  "create entity",
  "delete entity",
  "add component",
  "remove component",
  "add remove component",
  "iteration",
  "heterogeneous iter",
  "pristine iter",
  "churn iter",
  "read",
  "write"
]

let metricWidth = 20
let labelWidth = 4
let valueWidth = 10
let winnerMark = "*"

type Cell = tuple[time, mem: string]

var comparisons = Table[string, Table[string, Cell]]()
var suiteOrder: seq[string] = @[]

# Time and memory are stacked
let firstColumnWidth = metricWidth + 1 + labelWidth

# Each value is rendered as " <value> <mark> ", where the mark is the winner
let columnWidth = valueWidth + 4

proc rule(left: string, right: string, join: string, fill: string, columnCount: int): string =
  result = left & fill.repeat(firstColumnWidth + 2) & join
  for i in 0 ..< columnCount:
    result &= fill.repeat(columnWidth) & (if i == columnCount - 1: right else: join)

proc header(infos: seq[string]): string =
  result = "║ " & " ".repeat(firstColumnWidth) & " ║"

  for info in infos:
    let name = if info.runeLen > columnWidth: info.runeSubStr(0, columnWidth) else: info
    result &= name.center(columnWidth) & "║"

proc line(name, label: string, values: seq[tuple[value: string, won: bool]]): string =
  ## One half of a metric: every suite's time, or every suite's memory. `name`
  ## is blank on the memory line, which the label alone identifies.
  result = "║ " & name.alignLeft(metricWidth) & " " & label.alignLeft(labelWidth) & " ║"

  for (value, won) in values:
    let mark = if won: winnerMark else: " "
    result &= " " & unicode.align(value, valueWidth) & " " & mark & " ║"

proc toNumber(value: string, units: openArray[(string, float)]): float =
  ## Turns a formatted measurement ("12.34 µs", "1.41 MB") back into a comparable number.
  let parts = strutils.splitWhitespace(value)
  if parts.len != 2:
    return Inf

  var scale = Inf
  for (suffix, factor) in units:
    if parts[1] == suffix:
      scale = factor
  if scale == Inf:
    return Inf

  try:
    return parseFloat(parts[0]) * scale
  except ValueError:
    return Inf

proc toSeconds(time: string): float =
  time.toNumber({"ns": 1e-9, "µs": 1e-6, "ms": 1e-3, "s": 1.0})

proc toBytes(mem: string): float =
  mem.toNumber({"B": 1.0, "KB": 1024.0, "MB": 1024.0 * 1024.0})

proc winners(values: Table[string, float]): HashSet[string] =
  ## The suites tied for the lowest value. A metric only one suite reports is
  ## not a contest, so it has no winner to mark.
  result = initHashSet[string]()
  if values.len < 2:
    return

  var best = Inf
  for value in values.values:
    if value > 0:
      best = min(best, value)

  if best == Inf:
    return

  for suite, value in values:
    if value == best:
      result.incl(suite)

for metric in metrics:
  comparisons[metric] = Table[string, Cell]()

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
      comparisons[metric][bench] = (time: parts[1].strip(), mem: parts[2].strip())

echo ""
echo rule("╔", "╗", "╦", "═", suiteOrder.len)
echo header(suiteOrder)
echo rule("╠", "╣", "╬", "═", suiteOrder.len)

for index, metric in metrics:
  var timeValues = Table[string, float]()
  var memValues = Table[string, float]()

  for suite, results in comparisons[metric]:
    timeValues[suite] = results.time.toSeconds
    memValues[suite] = results.mem.toBytes

  let timeWinners = winners(timeValues)
  let memWinners = winners(memValues)

  var times: seq[tuple[value: string, won: bool]] = @[]
  var mems: seq[tuple[value: string, won: bool]] = @[]

  for suite in suiteOrder:
    if suite in comparisons[metric]:
      let results = comparisons[metric][suite]
      times.add((results.time, suite in timeWinners))
      mems.add((results.mem, suite in memWinners))
    else:
      times.add(("-", false))
      mems.add(("-", false))

  if index > 0:
    echo rule("╟", "╢", "╫", "─", suiteOrder.len)

  echo line(metric, "time", times)
  echo line("", "mem", mems)

echo rule("╚", "╝", "╩", "═", suiteOrder.len)
echo ""
echo winnerMark & " marks the best value on the line, time and memory judged separately."
