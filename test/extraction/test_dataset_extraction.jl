# using Base.Test
# using AutoRisk

# const NUM_FEATURES = 142
# const NUM_TARGETS = 5

function test_extract_vehicle_frame_targets()
    timestep = 0.1
    num_veh = 2
    models = Dict{Int, DriverModel}()

    # two static drivers not in a collision
    mlon = StaticLongitudinalDriver(0.)
    models[1] = Tim2DDriver(timestep, mlon = mlon)
    models[2] = Tim2DDriver(timestep, mlon = mlon)
    roadway = gen_straight_roadway(1, 50.)
    scene = Scene(num_veh)
    road_idx = RoadIndex(proj(VecSE2(0.0, 0.0, 0.0), roadway))
    road_pos = 10.
    base_speed = 1.
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_state = move_along(veh_state, roadway, road_pos)
    veh_def = VehicleDef(1, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_def = VehicleDef(2, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))
    rec = SceneRecord(500, .1, num_veh)
    T = 1.
    simulate!(scene, models, roadway, rec, T)

    targets = Array{Float64}(NUM_TARGETS, 2)
    fill!(targets, 0)
    veh_idx = 1
    t_idx = 1
    extract_vehicle_frame_targets!(rec, roadway, targets, veh_idx, t_idx, 0)
    veh_idx = 2
    t_idx = 2
    extract_vehicle_frame_targets!(rec, roadway, targets, veh_idx, t_idx, 0)

    @test all(abs(targets) .< 1e-8)

    # then in a collision
    scene[2].state = VehicleState(Frenet(road_idx, roadway), roadway, 12.)
    T = .9
    simulate!(scene, models, roadway, rec, T)

    veh_idx = 1
    t_idx = 1
    extract_vehicle_frame_targets!(rec, roadway, targets, veh_idx, t_idx, 0)
    veh_idx = 2
    t_idx = 2
    extract_vehicle_frame_targets!(rec, roadway, targets, veh_idx, t_idx, 0)

    @test targets[2,1] == 1.0
    @test abs(targets[4,1]) < 1e-8
    @test abs(targets[5,1]) < 1e-8

    @test targets[3,2] == 1.0
    @test abs(targets[4,2]) < 1e-8
    @test targets[5,2] == 1.0
end

function test_extract_frame_targets()
    # without changing index
    timestep = 0.1
    num_veh = 2
    models = Dict{Int, DriverModel}()
    mlon = StaticLongitudinalDriver(0.)
    models[1] = Tim2DDriver(timestep, mlon = mlon)
    models[2] = Tim2DDriver(timestep, mlon = mlon)
    roadway = gen_straight_roadway(1, 50.)
    scene = Scene(num_veh)
    road_idx = RoadIndex(proj(VecSE2(0.0, 0.0, 0.0), roadway))
    road_pos = 10.
    base_speed = 1.
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_state = move_along(veh_state, roadway, road_pos)
    veh_def = VehicleDef(1, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_def = VehicleDef(2, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))
    rec = SceneRecord(500, .1, num_veh)
    T = 1.
    simulate!(scene, models, roadway, rec, T)

    targets = Array{Float64}(NUM_TARGETS, 2)
    fill!(targets, 0)
    veh_id_to_idx = Dict(1=>1,2=>2)
    veh_idx_can_change = false
    done = Set{Int64}()
    pastframe = 0
    extract_frame_targets!(rec, roadway, targets, veh_id_to_idx,
        veh_idx_can_change, done, pastframe)

    @test all(abs(targets) .< 1e-8)

    T = .9
    scene[2].state = VehicleState(Frenet(road_idx, roadway), roadway, 12.)
    simulate!(scene, models, roadway, rec, T)

    fill!(targets, 0)
    extract_frame_targets!(rec, roadway, targets, veh_id_to_idx,
        veh_idx_can_change, done, pastframe)

    @test targets[2,1] == 1.0
    @test abs(targets[4,1]) < 1e-8
    @test abs(targets[5,1]) < 1e-8
    @test targets[3,2] == 1.0
    @test abs(targets[4,2]) < 1e-8
    @test targets[5,2] == 1.0
    @test done == Set([1,2])

    # with changing index
    scene[2].state = VehicleState(Frenet(road_idx, roadway), roadway, 13.)
    simulate!(scene, models, roadway, rec, T)
    done = Set{Int64}()
    veh_idx_can_change = true
    fill!(targets, 0)
    extract_frame_targets!(rec, roadway, targets, veh_id_to_idx,
        veh_idx_can_change, done, pastframe)

    @test targets[2,1] == 1.0
    @test abs(targets[4,1]) < 1e-8
    @test targets[3,2] == 1.0
    @test abs(targets[4,2]) < 1e-8
    @test done == Set([1,2])
end

function test_extract_targets()

    timestep = 0.1
    num_veh = 2
    models = Dict{Int, DriverModel}()
    mlon = StaticLongitudinalDriver(0.)
    models[1] = Tim2DDriver(timestep, mlon = mlon)
    models[2] = Tim2DDriver(timestep, mlon = mlon)
    roadway = gen_straight_roadway(1, 50.)
    scene = Scene(num_veh)
    road_idx = RoadIndex(proj(VecSE2(0.0, 0.0, 0.0), roadway))
    road_pos = 10.
    base_speed = 1.
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_state = move_along(veh_state, roadway, road_pos)
    veh_def = VehicleDef(1, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_def = VehicleDef(2, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))
    rec = SceneRecord(500, .1, num_veh)
    T = 1.
    simulate!(scene, models, roadway, rec, T)
    targets = Array{Float64}(NUM_TARGETS,2)
    fill!(targets, 0)
    veh_id_to_idx = Dict(1=>1,2=>2)
    veh_idx_can_change = true
    extract_targets!(rec, roadway, targets, veh_id_to_idx, veh_idx_can_change)

    @test abs(targets[1,1]) < 1e-8
    @test abs(targets[2,1]) < 1e-8
    @test abs(targets[1,2]) < 1e-8
    @test abs(targets[2,2]) < 1e-8

    fill!(targets, 0)
    scene[2].state = VehicleState(Frenet(road_idx, roadway), roadway, 9.5)
    models[1] = Tim2DDriver(timestep, mlon = StaticLongitudinalDriver(-5.))
    simulate!(scene, models, roadway, rec, T)
    extract_targets!(rec, roadway, targets, veh_id_to_idx, veh_idx_can_change)

    @test targets[2,1] == 1.0
    @test targets[4,1] == 1.0
    @test targets[3,2] == 1.0
    @test abs(targets[4,2]) < 1e-8
end

function test_pull_features()
    # add three vehicles and specifically check neighbor features
    timestep = 0.1
    num_veh = 3
    # one lane roadway
    roadway = gen_straight_roadway(1, 100.)
    scene = Scene(num_veh)

    models = Dict{Int, DriverModel}()

    # 1: first vehicle, moving the fastest
    mlon = StaticLongitudinalDriver(2.)
    models[1] = Tim2DDriver(timestep, mlon = mlon)
    road_idx = RoadIndex(proj(VecSE2(0.0, 0.0, 0.0), roadway))
    base_speed = 2.
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_def = VehicleDef(1, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))

    # 2: second vehicle, in the middle, moving at intermediate speed
    mlon = StaticLongitudinalDriver(1.)
    models[2] = Tim2DDriver(timestep, mlon = mlon)
    base_speed = 1.
    road_pos = 10.
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_state = move_along(veh_state, roadway, road_pos)
    veh_def = VehicleDef(2, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))

    # 3: thrid vehicle, in the front, not moving
    mlon = StaticLongitudinalDriver(0.)
    models[3] = Tim2DDriver(timestep, mlon = mlon)
    base_speed = 0.
    road_pos = 20.
    veh_state = VehicleState(Frenet(road_idx, roadway), roadway, base_speed)
    veh_state = move_along(veh_state, roadway, road_pos)
    veh_def = VehicleDef(3, AgentClass.CAR, 5., 2.)
    push!(scene, Vehicle(veh_state, veh_def))

    # simulate the scene for 1 second
    rec = SceneRecord(500, .1, num_veh)
    T = 1.

    # simulate here because some features need priming
    simulate!(scene, models, roadway, rec, T)
    features = Array{Float64}(NUM_FEATURES, 1, num_veh)


    ext = MultiFeatureExtractor()
    pull_features!(ext, rec, roadway, models, features)

    @test features[3,1] ≈ 4.
    @test features[4,1] == 5.
    @test features[9,1] ≈ 2.
    @test features[21,1] == 0.
    @test features[22,1] == 0.
    @test features[15,1] ≈ 3.5 / 4.
    @test features[17,1] ≈ 3.5 / 2.

    @test features[3,2] ≈ 2.
    @test features[4,2] == 5.
    @test features[9,2] ≈ 1.
    @test features[15,2] ≈ 3.5 / 2.
    @test features[17,2] ≈ 3.5 / 2.

    @test features[3,3] ≈ 0.
    @test features[4,3] == 5.
    @test features[9,3] ≈ 0.
    @test features[15,3] ≈ 30.0
    @test features[17,3] ≈ 0.0
end

@time test_extract_vehicle_frame_targets()
@time test_extract_frame_targets()
@time test_extract_targets()
@time test_pull_features()