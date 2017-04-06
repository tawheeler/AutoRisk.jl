function build_debug_dataset_collector(;
        output_filepath = "../data/test_dataset_collector.h5",
        num_samples = 10,
        feature_dim = NUM_FEATURES,
        target_dim = NUM_TARGETS,
        chunk_dim = 10,
        min_num_veh = 3,
        max_num_veh = 3,
        min_base_speed = 20.,
        max_base_speed = 40.,
        min_vehicle_length = 3.,
        max_vehicle_length = 7.,
        min_vehicle_width = 1.,
        max_vehicle_width = 3.,
        min_init_dist = 10.,
        max_init_dist = 30.,
        rng = MersenneTwister(1),
        num_lanes = 3,
        prime_time = 10.,
        sampling_time = 5.,
        init_file = true,
        feature_timesteps = 1,
        roadway_length = 400.,
        roadway_radius = 200.,
        lon_σ = 0.,
        lat_σ = 0.)

    seeds = collect(1:num_samples)
    max_num_samples = num_samples * max_num_veh

    # roadway gen
    roadway = gen_stadium_roadway(num_lanes, length = roadway_length,
        radius = roadway_radius)
    roadway_gen = StaticRoadwayGenerator(roadway)

    # scene gen
    scene = Scene(max_num_veh)
    scene_gen = HeuristicSceneGenerator(
        min_num_veh,
        max_num_veh,
        min_base_speed,
        max_base_speed,
        min_vehicle_length,
        max_vehicle_length,
        min_vehicle_width,
        max_vehicle_width,
        min_init_dist,
        max_init_dist,
        rng)

    params = [get_aggressive_behavior_params(lon_σ = lon_σ, lat_σ = lat_σ)]
    weights = WeightVec([1.])
    timestep = 0.1
    behavior_gen = PredefinedBehaviorGenerator(timestep, params, weights)
    models = Dict{Int, DriverModel}()

    # evaluator
    ext = MultiFeatureExtractor()
    num_runs::Int64 = 50
    prime_time::Float64 = 2.
    sampling_time::Float64 = 3.
    veh_idx_can_change::Bool = false
    max_num_scenes = Int((prime_time + sampling_time) / .1)
    rec::SceneRecord = SceneRecord(max_num_scenes, .1, max_num_veh)
    features::Array{Float64} = Array{Float64}(feature_dim, feature_timesteps,
        max_num_veh)
    targets::Array{Float64} = Array{Float64}(target_dim, max_num_veh)
    agg_targets::Array{Float64} = Array{Float64}(target_dim, max_num_veh)
    rng::MersenneTwister = MersenneTwister(1)
    eval = MonteCarloEvaluator(ext, num_runs, timestep, prime_time, sampling_time,
        veh_idx_can_change, rec, features, targets, agg_targets, rng)

    # dataset
    dataset = Dataset(output_filepath, feature_dim, feature_timesteps, target_dim,
        max_num_samples, chunk_dim = chunk_dim, init_file = init_file)

    # collector
    col = DatasetCollector(seeds, roadway_gen, scene_gen, behavior_gen, eval,
        dataset, scene, models, roadway)

    return col
end