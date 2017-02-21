export
    RoadwayGenerator,
    StaticRoadwayGenerator,
    reset!

"""
# Description:
    - RoadwayGenerator is the abstract type underlying the roadway generators.
"""
abstract RoadwayGenerator

Base.rand(gen::RoadwayGenerator) = error("rand not implemented for $(typeof(scene_generator))")
Base.srand(gen::RoadwayGenerator, seed) = error("srand not implemented for $(typeof(scene_generator)) and $(typeof(seed))")

"""
# Description:
    - StaticRoadwayGenerator has a single roadway that it always returns.
"""
type StaticRoadwayGenerator <: RoadwayGenerator
    roadway::Roadway
end

Base.rand(gen::StaticRoadwayGenerator) = gen.roadway
Base.srand(gen::StaticRoadwayGenerator, seed) = gen
