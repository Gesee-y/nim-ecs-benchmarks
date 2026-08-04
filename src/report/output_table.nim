## Renders a report as a box-drawn table, one column per suite.

import std/[strutils, unicode, tables]
import parser

const
  metricWidth = 20
  labelWidth = 4
  valueWidth = 10
  winnerMark = "*"

# Time and memory are stacked under a single metric name
const firstColumnWidth = metricWidth + 1 + labelWidth

# Each value is rendered as " <value> <mark> ", where the mark is the winner
const columnWidth = valueWidth + 4

type Value = tuple[value: string, won: bool]

proc rule(left: string, right: string, join: string, fill: string, columnCount: int): string =
  result = left & fill.repeat(firstColumnWidth + 2) & join
  for i in 0 ..< columnCount:
    result &= fill.repeat(columnWidth) & (if i == columnCount - 1: right else: join)

proc header(infos: seq[string]): string =
  result = "║ " & " ".repeat(firstColumnWidth) & " ║"

  for info in infos:
    let name = if info.runeLen > columnWidth: info.runeSubStr(0, columnWidth) else: info
    result &= name.center(columnWidth) & "║"

proc line(name, label: string, values: seq[Value]): string =
  result = "║ " & name.alignLeft(metricWidth) & " " & label.alignLeft(labelWidth) & " ║"

  for (value, won) in values:
    let mark = if won: winnerMark else: " "
    result &= " " & unicode.align(value, valueWidth) & " " & mark & " ║"

proc renderTable*(report: Report): string =
  let names = report.suiteNames

  var lines = @[
    rule("╔", "╗", "╦", "═", names.len),
    header(names),
    rule("╠", "╣", "╬", "═", names.len)
  ]

  var first = true

  for metric in report.metrics:
    var times, mems: seq[Value]

    for suite in report.suites:
      if metric in suite.measurements:
        let measured = suite.measurements[metric]
        times.add((measured.time, measured.timeWinner))
        mems.add((measured.mem, measured.memWinner))
      else:
        times.add(("-", false))
        mems.add(("-", false))

    if not first:
      lines.add(rule("╟", "╢", "╫", "─", names.len))
    first = false

    lines.add(line(metric, "time", times))
    lines.add(line("", "mem", mems))

  lines.add(rule("╚", "╝", "╩", "═", names.len))
  lines.add("")
  lines.add(winnerMark & " marks the best value on the line, time and memory judged separately.")

  return lines.join("\n")
