import times, math, tables, random, common
import ../libs/polymorph/src/polymorph

# =========================
# Benchmark template
# =========================
import benchmarks

# =========================
# Components
# =========================

register defaultCompOpts:
  type
    Position = object
      x, y: float32
    Velocity = object
      x, y: float32
    Acceleration = object
      x, y: float32
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

template reset(ents: var seq[EntityRef]) =
  for e in ents:
    if e.alive:
      e.delete()
  ents.setLen(0)

proc runPolyBenchmarks() =
  var suite = initSuite("Polymorph")

  # 1. Create Entity
  var entsCreate: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "create entity",
    SAMPLE,
    WARMUP,
    (
      entsCreate.reset()
    ),
    (
      for i in 0..<ENTITY_COUNT:
        entsCreate.add newEntityWith(
          Position(x: 1.0, y: 1.0),
          Velocity(x: 1.0, y: 1.0)
        )
    )
  )
  showDetailed(suite.benchmarks[^1])
  entsCreate.reset()

  # 2. Delete Entity
  var entsDelete: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "delete entity",
    SAMPLE,
    WARMUP,
    (
      entsDelete.reset();
      for i in 0..<ENTITY_COUNT:
        entsDelete.add newEntityWith(Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0))
    ),
    (
      for e in entsDelete:
        e.delete()
    )
  )
  showDetailed(suite.benchmarks[^1])
  entsDelete.reset()

  # 3. Add Component
  var entsAdd: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "add component",
    SAMPLE,
    WARMUP,
    (
      entsAdd.reset();
      for i in 0..<ENTITY_COUNT:
        entsAdd.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in entsAdd:
        e.addComponent Velocity(x: 1.0, y: 1.0)
    )
  )
  showDetailed(suite.benchmarks[^1])
  entsAdd.reset()

  # 4. Remove Component
  var entsRemove: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "remove component",
    SAMPLE,
    WARMUP,
    (
      entsRemove.reset();
      for i in 0..<ENTITY_COUNT:
        entsRemove.add newEntityWith(Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0))
    ),
    (
      for e in entsRemove:
        e.removeComponent Velocity
    )
  )
  showDetailed(suite.benchmarks[^1])
  entsRemove.reset()

  # 5. Add + Remove Component
  var entsAddRemove: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "add remove component",
    SAMPLE,
    WARMUP,
    (
      entsAddRemove.reset();
      for i in 0..<ENTITY_COUNT:
        entsAddRemove.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in entsAddRemove:
        e.addComponent Velocity(x: 1.0, y: 1.0)
        e.removeComponent Velocity
    )
  )
  showDetailed(suite.benchmarks[^1])
  entsAddRemove.reset()

  # 6. Iteration
  var entsIter: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "iteration",
    SAMPLE,
    WARMUP,
    (
      entsIter.reset();
      for i in 0..<ENTITY_COUNT:
        entsIter.add newEntityWith(Position(x: 1.0, y: 1.0), Velocity(x: 1.0, y: 1.0))
    ),
    (
      runMovement()
    )
  )
  showDetailed(suite.benchmarks[^1])
  entsIter.reset()

  # 7. Read
  var s = 0'f32
  var entsRead: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "read",
    SAMPLE,
    WARMUP,
    (
      entsRead.reset();
      for i in 0..<ENTITY_COUNT:
        entsRead.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in entsRead:
        s += e.fetchComponent(Position).x
    )
  )
  showDetailed(suite.benchmarks[^1])
  blackBox(s)
  entsRead.reset()

  # 8. Write
  var entsWrite: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "write",
    SAMPLE,
    WARMUP,
    (
      entsWrite.reset();
      for i in 0..<ENTITY_COUNT:
        entsWrite.add newEntityWith(Position(x: 1.0, y: 1.0))
    ),
    (
      for e in entsWrite:
        e.fetchComponent(Position).x = s
    )
  )
  showDetailed(suite.benchmarks[^1])
  blackBox(s)
  entsWrite.reset()

  var rng = initRand(42)

  var entsHetero: seq[EntityRef]
  suite.add benchmarkWithSetup(
    "heterogeneous iter",
    SAMPLE,
    WARMUP,
    (
      entsHetero.reset();
      for i in 0..<ENTITY_COUNT:
        let e = newEntity()
        for j in 0..<10:
          if rng.rand(1.0) < SELECTION_THRESHOLD:
            case j
            of 0: e.addComponent Position(x: 1.0, y: 1.0)
            of 1: e.addComponent Velocity(x: 1.0, y: 1.0)
            of 2: e.addComponent Acceleration(x: 1.0, y: 1.0)
            of 3: e.addComponent Rotation(angle: 0.5)
            of 4: e.addComponent Scale(sx: 1.0, sy: 1.0)
            of 5: e.addComponent Mass(value: 1.0)
            of 6: e.addComponent Force(fx: 1.0, fy: 1.0)
            of 7: e.addComponent Torque(value: 1.0)
            of 8: e.addComponent Energy(value: 1.0)
            of 9: e.addComponent Friction(coef: 0.5)
            else: discard
        entsHetero.add e
    ),
    (
      runMovement()
    )
  )
  showDetailed(suite.benchmarks[^1])
  entsHetero.reset()

  suite.showSummary()
  suite.saveSummary("poly")

if isMainModule:
  runPolyBenchmarks()
