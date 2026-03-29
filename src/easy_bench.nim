import times, math, tables
import ../libs/easyess/src/easyess

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

comp:
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
# Systems
# =========================

sys [Position, Velocity], "movement":
  proc moveSystem(item: Item) =
    # item is (ecs, entity)
    # templates position and velocity are generated
    position.x += velocity.x
    position.y += velocity.y

# =========================
# World setup
# =========================

createECS(ECSConfig(maxEntities: 20000))

# =========================
# Benchmarks
# =========================

proc runEasyBenchmarks() =
  var suite = initSuite("Easyess")

  # ------------------------------
  # Create entity
  # ------------------------------
  # Easyess doesn't have a direct "create multiple" without components in a single call like Cruise
  # But we can simulate it.
  
  suite.add benchmarkWithSetup(
    "create entity",
    SAMPLE,
    WARMUP,
    (
      var ecs = newECS()
      var ents: seq[Entity]
    ),
    (
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        (ecs, e).addVelocity(Velocity(x: 1.0, y: 1.0))
        ents.add e
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
      var ecs = newECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        (ecs, e).addVelocity(Velocity(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for e in ents:
        ecs.removeEntity(e)
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
      var ecs = newECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for e in ents:
        (ecs, e).addComponent(Velocity(x: 1.0, y: 1.0))
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
      var ecs = newECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        (ecs, e).addVelocity(Velocity(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for e in ents:
        (ecs, e).removeComponent(Velocity)
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
      var ecs = newECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for e in ents:
        (ecs, e).addComponent(Velocity(x: 1.0, y: 1.0))
        (ecs, e).removeComponent(Velocity)
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
      var ecs = newECS()
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        (ecs, e).addVelocity(Velocity(x: 1.0, y: 1.0))
    ),
    (
      ecs.runMovement()
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
      var ecs = newECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for e in ents:
        s += (ecs, e).position.x
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
      var ecs = newECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        let e = ecs.newEntity("bench")
        (ecs, e).addPosition(Position(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for e in ents:
        (ecs, e).position = Position(x: s, y: s)
    )
  )
  showDetailed(suite.benchmarks[7])

  suite.showSummary()
  suite.saveSummary("easy")

if isMainModule:
  runEasyBenchmarks()
