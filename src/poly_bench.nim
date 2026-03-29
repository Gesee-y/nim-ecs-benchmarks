import times, math, tables
import ../libs/polymorph/src/polymorph

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

register defaultCompOpts:
  type
    Position = object
      x, y: float32
    Velocity = object
      x, y: float32

# =========================
# Systems
# =========================

makeSystem "movement", [Position, Velocity]:
  all:
    position.x += velocity.x
    position.y += velocity.y

# =========================
# World setup
# =========================

makeEcs()
commitSystems "runMovement"

# =========================
# Benchmarks
# =========================

proc runPolyBenchmarks() =
  var suite = initSuite("Polymorph")

  # 1. Create Entity
  suite.add benchmarkWithSetup(
    "create entity",
    SAMPLE,
    WARMUP,
    (
      # We can't actually recreate the ECS types since it's generative.
      # But we can clean up entities if needed.
      # For creation, we just create them.
      var ents: seq[EntityRef]
    ),
    (
      for i in 0..<ENTITY_COUNT:
        ents.add newEntityWith(
          Position(x: 1.0, y: 1.0),
          Velocity(x: 1.0, y: 1.0)
        )
      # Cleanup after each sample to avoid memory overflow
      for e in ents: e.delete()
      ents.setLen(0)
    )
  )
  showDetailed(suite.benchmarks[0])

  # 2. Delete Entity
  suite.add benchmarkWithSetup(
    "delete entity",
    SAMPLE,
    WARMUP,
    (
      var ents: seq[EntityRef]
      for i in 0..<ENTITY_COUNT:
        ents.add newEntityWith(Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0))
    ),
    (
      for e in ents:
        e.delete()
    )
  )
  showDetailed(suite.benchmarks[1])

  # 3. Add Component
  suite.add benchmarkWithSetup(
    "add component",
    SAMPLE,
    WARMUP,
    (
      var ents: seq[EntityRef]
      for i in 0..<ENTITY_COUNT:
        ents.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in ents:
        e.addComponent Velocity(x: 1.0, y: 1.0)
      
      # Cleanup: remove component for next sample or delete entity
      # Actually it's easier to just delete entity in teardown if needed.
      # But here we just want to measure add.
      for e in ents: e.delete()
      ents.setLen(0)
    )
  )
  showDetailed(suite.benchmarks[2])

  # 4. Remove Component
  suite.add benchmarkWithSetup(
    "remove component",
    SAMPLE,
    WARMUP,
    (
      var ents: seq[EntityRef]
      for i in 0..<ENTITY_COUNT:
        ents.add newEntityWith(Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0))
    ),
    (
      for e in ents:
        e.removeComponent Velocity
      
      for e in ents: e.delete()
      ents.setLen(0)
    )
  )
  showDetailed(suite.benchmarks[3])

  # 5. Add + Remove Component
  suite.add benchmarkWithSetup(
    "add remove component",
    SAMPLE,
    WARMUP,
    (
      var ents: seq[EntityRef]
      for i in 0..<ENTITY_COUNT:
        ents.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in ents:
        e.addComponent Velocity(x: 1.0, y: 1.0)
        e.removeComponent Velocity
      
      for e in ents: e.delete()
      ents.setLen(0)
    )
  )
  showDetailed(suite.benchmarks[4])

  # 6. Iteration
  var entsIter: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "iteration",
    SAMPLE,
    WARMUP,
    (
      # Cleanup previous sample
      for e in entsIter: e.delete()
      entsIter.setLen(0)
      for i in 0..<ENTITY_COUNT:
        entsIter.add newEntityWith(Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0))
    ),
    (
      runMovement()
    )
  )
  showDetailed(suite.benchmarks[5])

  # 7. Read
  var s = 0'f32
  suite.add benchmarkWithSetup(
    "read",
    SAMPLE,
    WARMUP,
    (
      var ents: seq[EntityRef]
      for i in 0..<ENTITY_COUNT:
        ents.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in ents:
        s += e.fetchComponent(Position).x
    )
  )
  showDetailed(suite.benchmarks[6])

  # 8. Write
  suite.add benchmarkWithSetup(
    "write",
    SAMPLE,
    WARMUP,
    (
      var ents: seq[EntityRef]
      for i in 0..<ENTITY_COUNT:
        ents.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in ents:
        e.fetchComponent(Position).x = s
    )
  )
  showDetailed(suite.benchmarks[7])

  suite.showSummary()
  suite.saveSummary("poly")

if isMainModule:
  runPolyBenchmarks()
