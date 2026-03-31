import ../libs/pirata/src/pirata

include "benchmarks.nim"

const
  sample = 1000
  warmup = 1
  entityCount = 10000
  worldCapacity = entityCount * 2

type
  ComponentKind = enum
    ckPosition
    ckVelocity

  Position = object
    x, y: float32

  Velocity = object
    x, y: float32

proc initWorld(): PirataWorld[ComponentKind] =
  result = newPirata[ComponentKind](worldCapacity)
  result.register(ckPosition, Position)
  result.register(ckVelocity, Velocity)

proc spawnEntities(
    world: var PirataWorld[ComponentKind]; entities: var seq[Entity];
    withPosition, withVelocity: bool) =
  entities.setLen(entityCount)

  for i in 0..<entityCount:
    let entity = world.spawn()
    entities[i] = entity

    if withPosition:
      world.add(entity, ckPosition, Position(x: 1.0, y: 1.0))

    if withVelocity:
      world.add(entity, ckVelocity, Velocity(x: 1.0, y: 1.0))

proc runPirataBenchmarks() =
  var suite = initSuite("Pirata")

  suite.add benchmarkWithSetup(
    "create entity",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
    ),
    (
      spawnEntities(world, entities, withPosition = true, withVelocity = true)
    )
  )
  showDetailed(suite.benchmarks[0])

  suite.add benchmarkWithSetup(
    "delete entity",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
      spawnEntities(world, entities, withPosition = true, withVelocity = true)
    ),
    (
      for entity in entities:
        world.destroy(entity)
    )
  )
  showDetailed(suite.benchmarks[1])

  suite.add benchmarkWithSetup(
    "add component",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
      spawnEntities(world, entities, withPosition = true, withVelocity = false)
    ),
    (
      for entity in entities:
        world.add(entity, ckVelocity, Velocity(x: 1.0, y: 1.0))
    )
  )
  showDetailed(suite.benchmarks[2])

  suite.add benchmarkWithSetup(
    "remove component",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
      spawnEntities(world, entities, withPosition = true, withVelocity = true)
    ),
    (
      for entity in entities:
        world.remove(entity, ckVelocity)
    )
  )
  showDetailed(suite.benchmarks[3])

  suite.add benchmarkWithSetup(
    "add remove component",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
      spawnEntities(world, entities, withPosition = true, withVelocity = false)
    ),
    (
      for entity in entities:
        world.add(entity, ckVelocity, Velocity(x: 1.0, y: 1.0))
        world.remove(entity, ckVelocity)
    )
  )
  showDetailed(suite.benchmarks[4])

  suite.add benchmarkWithSetup(
    "iteration",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
      spawnEntities(world, entities, withPosition = true, withVelocity = true)
    ),
    (
      for entity in world.query({ckPosition, ckVelocity}):
        let velocity = world.fetch(entity, ckVelocity, Velocity)
        var position = world.fetch(entity, ckPosition, Position)
        position.x += velocity.x
        position.y += velocity.y
    )
  )
  showDetailed(suite.benchmarks[5])

  var sum = 0'f32
  suite.add benchmarkWithSetup(
    "read",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
      spawnEntities(world, entities, withPosition = true, withVelocity = false)
    ),
    (
      for entity in entities:
        sum += world.fetch(entity, ckPosition, Position).x
    )
  )
  showDetailed(suite.benchmarks[6])

  suite.add benchmarkWithSetup(
    "write",
    sample,
    warmup,
    (
      var world = initWorld()
      var entities: seq[Entity] = @[]
      spawnEntities(world, entities, withPosition = true, withVelocity = false)
    ),
    (
      for entity in entities:
        var position = world.fetch(entity, ckPosition, Position)
        position.x = sum
        position.y = sum
    )
  )
  showDetailed(suite.benchmarks[7])

  suite.showSummary()
  suite.saveSummary("pirata")

if isMainModule:
  runPirataBenchmarks()
