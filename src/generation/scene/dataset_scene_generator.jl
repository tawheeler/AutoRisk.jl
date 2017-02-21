export DatasetSceneGenerator

type DatasetSceneGenerator <: SceneGenerator
    trajdata::Trajdata
    veh_ids::Vector{Int64}
    next_idx::Int64
end

function Base.rand!(scene::Scene, gen::DatasetSceneGenerator, roadway::Roadway)
    # get the first scene with the next veh_id and then increment
    frame_idx = get_first_frame_with_id(gen.trajdata, gen.veh_ids[gen.next_idx])
    get!(scene, gen.trajdata, frame_idx)
    gen.next_idx += 1
    return scene
end
Base.srand(gen::DatasetSceneGenerator, seed) = gen