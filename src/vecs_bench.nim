import times, math, tables
import ../../vecs/src/vecs

# =========================
# Benchmark template
# =========================
include "benchmarks.nim"

const SAMPLE = 1000
const WARMUP = 1
const ENTITY_COUNT = 10000

# =========================
# Components
# =========================

type
  Position = object
    x, y: float32

  Velocity = object
    x, y: float32

  Acceleration = object
    x, y: float32

  Tag = object

  Health = object
    hp: int

# =========================
# Benchmarks
# =========================

proc runVecsBenchmarks() =
  var suite = initSuite("Vecs")

  # ------------------------------
  # Create entity
  # ------------------------------
  suite.add benchmarkWithSetup(
    "create entity",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      var ents: seq[EntityId]
    ),
    (
      for i in 0..<ENTITY_COUNT:
        ents.add w.add((Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0)), Immediate)
    )
  )
  showDetailed(suite.benchmarks[0])

  # ------------------------------
  # Delete entity
  # ------------------------------
  suite.add benchmarkWithSetup(
    "delete entity",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      var ents: seq[EntityId]
      for i in 0..<ENTITY_COUNT:
        ents.add w.add((Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0)), Immediate)
    ),
    (
      for e in ents:
        w.remove(e, Immediate)
    )
  )
  showDetailed(suite.benchmarks[1])

  # ------------------------------
  # Add component
  # ------------------------------
  suite.add benchmarkWithSetup(
    "add component",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      var ents: seq[EntityId]
      for i in 0..<ENTITY_COUNT:
        ents.add w.add((Position(x: 1.0, y: 1.0),), Immediate)
    ),
    (
      for e in ents:
        w.add(e, Velocity(x: 1.0, y: 1.0), Immediate)
    )
  )
  showDetailed(suite.benchmarks[2])

  # ------------------------------
  # Remove component
  # ------------------------------
  suite.add benchmarkWithSetup(
    "remove component",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      var ents: seq[EntityId]
      for i in 0..<ENTITY_COUNT:
        ents.add w.add((Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0)), Immediate)
    ),
    (
      for e in ents:
        w.remove(e, Velocity, Immediate)
    )
  )
  showDetailed(suite.benchmarks[3])

  # ------------------------------
  # Add + Remove component
  # ------------------------------
  suite.add benchmarkWithSetup(
    "add remove component",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      var ents: seq[EntityId]
      for i in 0..<ENTITY_COUNT:
        ents.add w.add((Position(x: 1.0, y: 1.0),), Immediate)
    ),
    (
      for e in ents:
        w.add(e, Velocity(x: 1.0, y: 1.0), Immediate)
        w.remove(e, Velocity, Immediate)
    )
  )
  showDetailed(suite.benchmarks[4])

  # ------------------------------
  # Iteration
  # ------------------------------
  suite.add benchmarkWithSetup(
    "iteration",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      for i in 0..<ENTITY_COUNT:
        discard w.add((Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0)), Immediate)
      var q: Query[(Write[Position], Velocity)]
    ),
    (
      for (pos, vel) in w.query(q):
        pos.x += vel.x
        pos.y += vel.y
    )
  )
  showDetailed(suite.benchmarks[5])

  # ------------------------------
  # Read
  # ------------------------------
  var s = 0'f32
  suite.add benchmarkWithSetup(
    "read",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      var ents: seq[EntityId]
      for i in 0..<ENTITY_COUNT:
        ents.add w.add((Position(x: 1.0, y: 1.0),), Immediate)
    ),
    (
      for e in ents:
        s += w.read(e, Position).x
    )
  )
  showDetailed(suite.benchmarks[6])

  # ------------------------------
  # Write
  # ------------------------------
  suite.add benchmarkWithSetup(
    "write",
    SAMPLE,
    WARMUP,
    (
      var w = World()
      var ents: seq[EntityId]
      for i in 0..<ENTITY_COUNT:
        ents.add w.add((Position(x: 1.0, y: 1.0),), Immediate)
    ),
    (
      for e in ents:
        for pos in w.write(e, Position):
          pos.x = s
          pos.y = s
    )
  )
  showDetailed(suite.benchmarks[7])

  suite.showSummary()
  suite.saveSummary("vecs")

if isMainModule:
  runVecsBenchmarks()
