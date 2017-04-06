export
    BehaviorGenerator,
    reset!,
    build_driver

"""
# Description:
    - BehaviorGenerator is the abstract type underlying the behavior generators.
"""
abstract BehaviorGenerator

Base.rand(gen::BehaviorGenerator) = error("rand not implemented for $(gen)")

"""
# Description:
    - This method uses any behavior generator to populate a models dict with
        driver models

# Args:
    - gen: behavior generator to use
    - models: dict to populate
    - scene: scene that contains vehicles which correspond to the driver models
    - seed: random seed to use in populating the models
"""
function reset!{S,D,I}(
    gen::BehaviorGenerator,
    models::Dict{I, DriverModel},
    scene::EntityFrame{S,D,I},
    seed::Int64,
    )

    srand(seed)
    srand(gen.rng, seed)
    empty!(models)
    for veh in scene
        params = rand(gen)
        models[veh.def.id] = build_driver(params, get_timestep(gen), length(scene))
    end
end

"""
# Description:
    - Builds a driver using provided parameter set. This assumes usage of
        IDM, MOBIL, and ProportionalLaneTracker.

# Args:
    - p: params to use
    - num_vehicles: number of vehicles in the scene
"""
function build_driver(p::BehaviorParams, timestep::Float64, num_vehicles::Int64)
    mlon = IntelligentDriverModel(
        k_spd = p.idm.k_spd,
        δ = p.idm.δ,
        T = p.idm.T,
        v_des = p.idm.v_des,
        s_min = p.idm.s_min,
        a_max = p.idm.a_max,
        d_cmf = p.idm.d_cmf)
    mlon.σ = p.idm.σ
    mlat = ProportionalLaneTracker(
        σ = p.lat.σ,
        kp = p.lat.kp,
        kd = p.lat.kd)
    mlat.σ = p.lat.σ
    mlane = MOBIL(
        safe_decel = p.mobil.safe_decel,
        politeness = p.mobil.politeness,
        advantage_threshold = p.mobil.advantage_threshold)
    model = Tim2DDriver(
        rec = SceneRecord(1, timestep, num_vehicles),
        mlat = mlat,
        mlon = mlon,
        mlane = mlane)
    if p.idm.t_d != 0.0
        model = DelayedDriver(model, timestep, reaction_time = p.idm.t_d)
    end
    set_desired_speed!(model, p.idm.v_des)
    return model
end
