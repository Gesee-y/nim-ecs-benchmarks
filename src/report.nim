import std/[os, algorithm]
import report/[parser, output_table]

proc csvFiles(): seq[string] =
  result = commandLineParams()
  if result.len > 0:
    return

  for csvFile in walkFiles("*.csv"):
    result.add(csvFile)
  result.sort()

let report = parseFiles(csvFiles())

if report.suites.len == 0:
  echo "No benchmark CSVs found"
  quit(1)

echo ""
echo renderTable(report)
