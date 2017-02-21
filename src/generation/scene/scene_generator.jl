export
    SceneGenerator

"""
# Description:
    - SceneGenerator is the abstract type underlying the scene generators.
"""
abstract SceneGenerator

Base.rand!(scene::Scene, scene_generator::SceneGenerator, roadway::Roadway) = error("rand! not implemented for $(typeof(scene_generator))")
Base.rand(scene_generator::SceneGenerator, roadway::Roadway) = rand!(Scene(), scene_generator, roadway)
Base.srand(scene_generator::SceneGenerator, seed) = error("srand not implemented for $(typeof(scene_generator)) and $(typeof(seed))")
