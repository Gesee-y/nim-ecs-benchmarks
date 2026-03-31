import times, math, tables, random
import ../libs/miniecs/miniecs

# =========================
# Benchmark template
# =========================
include "benchmarks.nim"

const SAMPLE = 1000
const WARMUP = 1
const ENTITY_COUNT = 10000
const SELECTION_THRESHOLD = 0.1

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

  Rotation = object
    angle: float32
  Scale = object
    sx, sy: float32
  Mass = object
    value: float32
  Force = object
    fx, fy: float32
  Torque = object
    value: float32
  Energy = object
    value: float32
  Friction = object
    coef: float32

# =========================
# Benchmarks
# =========================

proc runMiniBenchmarks() =
  var suite = initSuite("MiniECS")

  # ------------------------------
  # Create entity
  # ------------------------------
  suite.add benchmarkWithSetup(
    "create entity",
    SAMPLE,
    WARMUP,
    (
      var ecs = newMiniECS()
      var ents: seq[Entity]
    ),
    (
      for i in 0..<ENTITY_COUNT:
        var e = ecs.newEntity()
        e.addComponent(Position(x: 1.0, y: 1.0))
        e.addComponent(Velocity(x: 1.0, y: 1.0))
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
      var ecs = newMiniECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        var e = ecs.newEntity()
        e.addComponent(Position(x: 1.0, y: 1.0))
        e.addComponent(Velocity(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for i in 0..<ENTITY_COUNT:
        destroy(ents[i].getID(), ecs)
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
      var ecs = newMiniECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        ents.add ecs.newEntity()
    ),
    (
      for i in 0..<ENTITY_COUNT:
        addComponent(ents[i].getID(), Position(x: 1.0, y: 1.0), ecs)
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
      var ecs = newMiniECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        var e = ecs.newEntity()
        e.addComponent(Position(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for i in 0..<ENTITY_COUNT:
        removeComponent(ents[i].getID(), Position, ecs)
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
      var ecs = newMiniECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        ents.add ecs.newEntity()
    ),
    (
      for i in 0..<ENTITY_COUNT:
        let id = ents[i].getID()
        addComponent(id, Position(x: 1.0, y: 1.0), ecs)
        removeComponent(id, Position, ecs)
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
      var ecs = newMiniECS()
      for i in 0..<ENTITY_COUNT:
        var e = ecs.newEntity()
        e.addComponent(Position(x: 1.0, y: 1.0))
        e.addComponent(Velocity(x: 1.0, y: 1.0))
    ),
    (
      for id, pos, vel in ecs.allWith(Position, Velocity):
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
      var ecs = newMiniECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        var e = ecs.newEntity()
        e.addComponent(Position(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for i in 0..<ENTITY_COUNT:
        s += getComponent(ents[i].getID(), Position, ecs).x
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
      var ecs = newMiniECS()
      var ents: seq[Entity]
      for i in 0..<ENTITY_COUNT:
        var e = ecs.newEntity()
        e.addComponent(Position(x: 1.0, y: 1.0))
        ents.add e
    ),
    (
      for i in 0..<ENTITY_COUNT:
        getComponent(ents[i].getID(), Position, ecs).x = s
    )
  )
  showDetailed(suite.benchmarks[7])

  var rng = initRand(42)
  suite.add benchmarkWithSetup(
    "heterogeneous iter",
    SAMPLE,
    WARMUP,
    (
      var ecs = newMiniECS()
      for i in 0..<ENTITY_COUNT:
        var e = ecs.newEntity()
        for j in 0..<10:
          if rng.rand(1.0) < SELECTION_THRESHOLD:
            case j
            of 0: e.addComponent(Position(x: 1.0, y: 1.0))
            of 1: e.addComponent(Velocity(x: 1.0, y: 1.0))
            of 2: e.addComponent(Acceleration(x: 1.0, y: 1.0))
            of 3: e.addComponent(Rotation(angle: 0.5))
            of 4: e.addComponent(Scale(sx: 1.0, sy: 1.0))
            of 5: e.addComponent(Mass(value: 1.0))
            of 6: e.addComponent(Force(fx: 1.0, fy: 1.0))
            of 7: e.addComponent(Torque(value: 1.0))
            of 8: e.addComponent(Energy(value: 1.0))
            of 9: e.addComponent(Friction(coef: 0.5))
            else: discard
    ),
    (
      for id, pos, vel in ecs.allWith(Position, Velocity):
        pos.x += vel.x
        pos.y += vel.y
    )
  )
  showDetailed(suite.benchmarks[^1])

  suite.showSummary()
  suite.saveSummary("mini")

if isMainModule:
  runMiniBenchmarks()
