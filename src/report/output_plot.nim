import std/[tables, algorithm], ggplotnim, ginger/backends, parser
import ginger except Scale

const
  palette = [
   "#2A9D8F", "#E76F51", "#F4A261", "#264653", "#E9C46A", "#A8DADC", "#457B9D", "#1D3557"
  ]

  micros = 1e6
  mebibytes = 1024.0 * 1024.0

  columns = 2
  panelWidth = 560
  panelHeight = 380

proc colors(report: Report): Table[string, Color] =
  var names = report.suiteNames
  names.sort()
  for index, name in names:
    result[name] = parseHtmlHex(palette[index mod palette.len])

proc panel(
  report: Report, metric, label: string, value: proc (m: Measurement): float
): GgPlot =
  ## One metric's bars. Suites that never reported it are left out rather than
  ## drawn as zero, and the panel is scaled to whatever is left.
  var suites: seq[string]
  var values: seq[float]

  for suite in report.suites:
    if metric notin suite.measurements:
      continue

    let measured = value(suite.measurements[metric])
    if measured == Inf:
      continue

    suites.add suite.name
    values.add measured

  let df = toDf({"suite": suites, "value": values})

  ggplot(df, aes(x = "suite", y = "value", fill = "suite")) +
    geom_bar(stat = "identity", position = "identity") +
    scale_fill_manual(report.colors) +
    ggtitle(metric & " (lower is better)") +
    xlab(" ", rotate = -30.0, alignTo = "right") +
    ylab(label) +
    backgroundColor(white) +
    gridLines(color = grey92) +
    hideLegend()

proc savePlot(
  report: Report, path, label: string, value: proc (m: Measurement): float
) =
  let rows = (metricOrder.len + columns - 1) div columns

  let texOptions = toTeXOptions(false, false, false, "", "", "", "htbp")
  let fType = parseFilename(path)
  let backend = fType.toBackend(texOptions)

  var image = initViewport(
    wImg = float(panelWidth * columns),
    hImg = float(panelHeight * rows),
    backend = backend,
    fType = fType
  )
  image.layout(cols = columns, rows = rows)

  for index, metric in metricOrder:
    var plot = report.panel(metric, label, value)
    plot.backend = backend
    plot.fType = fType

    let drawn = plot.ggcreate(width = panelWidth, height = panelHeight)
    image.embedAt(index, drawn.view)

  image.draw(path, texOptions)

proc saveTimePlot*(report: Report, path: string) =
  report.savePlot(path, "median time (µs)", proc (m: Measurement): float =
    m.seconds * micros
  )

proc saveMemoryPlot*(report: Report, path: string) =
  report.savePlot(path, "median memory (MiB)", proc (m: Measurement): float =
    m.bytes / mebibytes
  )
