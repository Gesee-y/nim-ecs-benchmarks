import ../libs/pirata/src/pirata
import random, common

import benchmarks, churn_common

const
  sample = 1000
  warmup = 0
  entityCount = 10000
  worldCapacity = entityCount * 2
  SELECTION_THRESHOLD = 0.1

type
  ComponentKind = enum
    ckPosition
    ckVelocity

# Composants supplémentaires — mêmes types que ci-dessus
# (les déclarer une seule fois dans un fichier commun si possible)

type
  HeteroKind = enum
    hkPosition
    hkVelocity
    hkAcceleration
    hkRotation
    hkScale
    hkMass
    hkFriction
    hkBounce
    hkLifetime
    hkEnergy

proc initWorldHetero(): PirataWorld[HeteroKind] =
  result = newPirata[HeteroKind](worldCapacity)
  result.register(hkPosition,     Position)
  result.register(hkVelocity,     Velocity)
  result.register(hkAcceleration, Acceleration)
  result.register(hkRotation,     Rotation)
  result.register(hkScale,        Scale)
  result.register(hkMass,         Mass)
  result.register(hkFriction,     Friction)
  result.register(hkBounce,       Bounce)
  result.register(hkLifetime,     Lifetime)
  result.register(hkEnergy,       Energy)

proc churnSpawn(world: var PirataWorld[ComponentKind]): Entity =
  result = world.spawn()
  world.add(result, ckPosition, Position(x: 1.0, y: 1.0))
  world.add(result, ckVelocity, Velocity(x: 1.0, y: 1.0))

proc churnDestroy(world: var PirataWorld[ComponentKind]; entity: Entity) =
  world.destroy(entity)

proc newChurnWorld(churned: bool): PirataWorld[ComponentKind] =
  result = newPirata[ComponentKind](ChurnCapacity)
  result.register(ckPosition, Position)
  result.register(ckVelocity, Velocity)
  result.populateChurn(churned)

proc churnIterate(world: var PirataWorld[ComponentKind]) =
  for entity in world.query({ckPosition, ckVelocity}):
    let pos = addr world.fetch(entity, ckPosition, Position)
    let vel = world.fetch(entity, ckVelocity, Velocity)
    pos.x += vel.x
    pos.y += vel.y

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

  var sHetero = 0.0
  suite.add benchmarkWithSetup(
    "heterogeneous iter",
    sample,
    warmup,
    (
      var world = initWorldHetero()
      var rng = initRand(42)
      var entities: seq[Entity]
      entities.setLen(entityCount)

      for i in 0..<entityCount:
        let e = world.spawn()
        entities[i] = e

      let optional = [hkPosition, hkVelocity,
        hkAcceleration, hkRotation, hkScale, hkMass,
        hkFriction, hkBounce, hkLifetime, hkEnergy
      ]

      for e in entities:
        for kind in optional:
          if rng.rand(1.0) < SELECTION_THRESHOLD:
            world.add(e, kind)
    ),
    (
      for entity in world.query({hkPosition, hkVelocity}):
        let velocity = world.fetch(entity, hkVelocity, Velocity)
        var position = world.fetch(entity, hkPosition, Position)
        position.x += velocity.x
        position.y += velocity.y
        sHetero += 1
    )
  )
  showDetailed(suite.benchmarks[^1])
  blackBox(sHetero)


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

  var s = 0.0
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
        s += velocity.x
    )
  )
  showDetailed(suite.benchmarks[5])
  blackBox(s)

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
  blackBox(sum)

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
        sum += 1
    )
  )
  showDetailed(suite.benchmarks[7])
  blackBox(sum)

  addChurnRows(suite, "Pirata")

  suite.showSummary()
  suite.saveSummary("pirata")

if isMainModule:
  runPirataBenchmarks()
