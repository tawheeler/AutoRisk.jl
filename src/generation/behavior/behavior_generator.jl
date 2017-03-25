export
    BehaviorGenerator,
    reset!,
    build_driver

"""
# Description:
    - BehaviorGenerator is the abstract type underlying the behavior generators.
"""
abstract BehaviorGenerator

Base.rand(gen::BehaviorGenerator) = error("rand not implemented for $(typeof(gen))")
Base.srand(gen::BehaviorGenerator, seed) = error("srand not implemented for $(typeof(gen)) and $(typeof(seed))")

"""
# Description:
    - This method uses any behavior generator to populate a models dict with
        driver models

# Args:
    - gen: behavior generator to use
    - models: dict to populate
    - scene: scene that contains vehicles which correspond to the driver models
"""
function Base.rand{D<:DriverModel}(gen::BehaviorGenerator, models::Dict{Int, D}, scene::Scene)
    empty!(models)
    for veh in scene.vehicles
        models[veh.def.id] = rand(gen)
    end
    return models
end