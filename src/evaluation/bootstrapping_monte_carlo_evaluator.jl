export
    BootstrappingMonteCarloEvaluator,
    bootstrap_targets!

"""
# Description:
    - MonteCarloEvaluator evaluates a set of {roadway, scene, models}
        by simulating them together many times and deriving features and
        targets from the results.
"""
type BootstrappingMonteCarloEvaluator <: Evaluator
    ext::AbstractFeatureExtractor
    num_runs::Int64
    prime_time::Float64
    sampling_time::Float64
    veh_idx_can_change::Bool

    rec::SceneRecord
    features::Array{Float64}
    feature_timesteps::Int64
    targets::Array{Float64}
    agg_targets::Array{Float64}

    prediction_features::Array{Float64}
    prediction_model::PredictionModel

    rng::MersenneTwister
    num_veh::Int64
    veh_id_to_idx::Dict{Int64, Int64}
    done::Set{Int64}

    """
    # Args:
        - num_runs: how many monte carlo runs to run
        - prime_time: "burn-in" time for the scene
        - sampling_time: time to sample the scene after burn-in
        - veh_idx_can_change: whether or not the vehicle indices in the scene
            can change over time
        - rec: record to use for storage of scenes
        - features: array in which to store features,
            shape = (feature_dim, max_num_veh)
        - targets: array in which to store targets for each monte carlo run,
            shape = (target_dim, max_num_veh)
        - agg_targets: aggregate target values accumulated across runs
        - rng: random number generator to use
    """
    function BootstrappingMonteCarloEvaluator(ext::AbstractFeatureExtractor,
            num_runs::Int64,
            prime_time::Float64,
            sampling_time::Float64,
            veh_idx_can_change::Bool,
            rec::SceneRecord,
            features::Array{Float64},
            targets::Array{Float64},
            agg_targets::Array{Float64},
            prediction_model::PredictionModel,
            rng::MersenneTwister = MersenneTwister(1))
        features_size = size(features)
        @assert length(features_size) == 3
        feature_timesteps = features_size[2]
        prediction_features = Array{Float64}(features_size)
        return new(ext, num_runs, prime_time, sampling_time,
            veh_idx_can_change, rec, features, feature_timesteps,
            targets, agg_targets, prediction_features, prediction_model,
            rng, 0, Dict{Int64, Int64}(), Set{Int}())
    end
end

function bootstrap_targets!(eval::BootstrappingMonteCarloEvaluator,
        models::Dict{Int, DriverModel}, roadway::Roadway)
    input_dim = size(eval.prediction_features, 1)
    fill!(eval.prediction_features, 0)
    for (veh_id, veh_idx) in eval.veh_id_to_idx

        if !in(veh_id, eval.done) && !any(eval.targets[1:3, veh_idx] .== 1)

            eval.prediction_features[:, veh_idx] = pull_features!(eval.ext, eval.rec, roadway, veh_idx, models)
            bootstrap_values = predict(eval.prediction_model, reshape(
                eval.prediction_features[:, veh_idx], (1, input_dim)))

            eval.targets[:, veh_idx] += bootstrap_values[:]
            eval.targets[:, veh_idx] = min(max(
                eval.targets[:, veh_idx], 0.0), 1.0)
        end
    end
end