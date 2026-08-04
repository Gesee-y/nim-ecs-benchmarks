import std/[strutils, tables]

const metricOrder* = [
  "iteration",
  "heterogeneous iter",
  "pristine iter",
  "churn iter",
  "create entity",
  "delete entity",
  "add component",
  "remove component",
  "add remove component",
  "read",
  "write"
]

type
  Measurement* = object
    time*: string   ## Median time, formatted for display
    mem*: string    ## Median memory, formatted for display
    seconds*: float ## Median time, for comparing against other suites
    bytes*: float   ## Median memory, for comparing against other suites
    timeWinner*: bool ## Whether this is the fastest time on its row
    memWinner*: bool  ## Whether this is the smallest memory on its row

  Suite* = object
    name*: string
    measurements*: Table[string, Measurement]

  Report* = object
    suites*: seq[Suite]

proc toNumber(value: string): float =
  try:
    return parseFloat(value.strip())
  except ValueError:
    return Inf

proc parseSuite*(csv: string): Suite =
  let lines = csv.splitLines()

  result.name = lines[0].split(',')[0].strip()

  for line in lines[1..^1]:
    let parts = line.split(',')
    if parts.len < 5:
      continue

    let metric = parts[0].strip()
    if metric notin metricOrder:
      continue

    result.measurements[metric] = Measurement(
      time: parts[1].strip(),
      mem: parts[2].strip(),
      seconds: parts[3].toNumber,
      bytes: parts[4].toNumber
    )

proc best(values: openArray[float]): float =
  result = Inf
  for value in values:
    if value > 0 and value < result:
      result = value

proc markWinners(report: var Report) =
  for metric in metricOrder:
    var seconds, bytes: seq[float]

    for suite in report.suites:
      if metric in suite.measurements:
        seconds.add(suite.measurements[metric].seconds)
        bytes.add(suite.measurements[metric].bytes)

    if seconds.len < 2:
      continue

    let bestTime = best(seconds)
    let bestMem = best(bytes)

    for suite in report.suites.mitems:
      if metric in suite.measurements:
        template measured: Measurement = suite.measurements[metric]
        measured.timeWinner = bestTime < Inf and measured.seconds == bestTime
        measured.memWinner = bestMem < Inf and measured.bytes == bestMem

proc parseFiles*(paths: openArray[string]): Report =
  for path in paths:
    let suite = parseSuite(readFile(path))
    if suite.name.len > 0:
      result.suites.add(suite)

  result.markWinners()

proc suiteNames*(report: Report): seq[string] =
  for suite in report.suites:
    result.add(suite.name)

iterator metrics*(report: Report): string =
  for metric in metricOrder:
    yield metric
