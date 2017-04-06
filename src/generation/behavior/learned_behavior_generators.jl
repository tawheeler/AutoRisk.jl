
export
    LearnedBehaviorGenerator,
    reset!,
    rand

type LearnedBehaviorGenerator <: BehaviorGenerator
    filepath::String
end
function reset!(
    gen::LearnedBehaviorGenerator,
    models::Dict{Int, DriverModel},
    scene::Scene,
    seed::Int64;
    timestep::Float64=0.1,
    )

    if length(models) == 0
        for veh in scene.vehicles
            if veh.def.id == 1
                extractor = MultiFeatureExtractor(gen.filepath)
                gru_layer = contains(gen.filepath, "gru")
                model = load_gaussian_mlp_driver(gen.filepath, extractor,
                    gru_layer = gru_layer)
                models[veh.def.id] = model
            else
                models[veh.def.id] = Tim2DDriver(timestep)
            end
        end
    end
    return models
end