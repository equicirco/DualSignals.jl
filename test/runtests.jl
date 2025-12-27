using Test
using DualSignals
using JSON3
using Dates

function build_valid_dataset()
    return DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(description="demo dataset", units_convention="units"),
        components=[
            Component(component_id="n1", component_type=DualSignals.node, name="Node 1"),
            Component(component_id="l1", component_type=DualSignals.link, name="Link 1"),
        ],
        constraints=[
            Constraint(
                constraint_id="c1",
                kind=DualSignals.balance,
                sense=DualSignals.eq,
                rhs=0.0,
                unit="MW",
                component_ids=["n1"],
                tags=["core", "balance"],
            ),
            Constraint(
                constraint_id="c2",
                kind=DualSignals.capacity,
                sense=DualSignals.le,
                rhs=100.0,
                unit="MW",
                component_ids=["l1"],
                tags=["limit"],
            ),
        ],
        constraint_solutions=[
            ConstraintSolution(constraint_id="c1", dual=1.5, activity=0.0, slack=0.0),
            ConstraintSolution(constraint_id="c2", dual=2.0, activity=90.0, slack=10.0),
        ],
        variables=[
            VariableValue(component_id="l1", name="flow", value=90.0, unit="MW"),
        ],
    )
end

@testset "DualSignals serialization" begin
    dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(description="demo dataset", units_convention="units"),
        components=[
            Component(component_id="n1", component_type=DualSignals.node, name="Node 1"),
            Component(component_id="l1", component_type=DualSignals.link, name="Link 1"),
        ],
        constraints=[
            Constraint(
                constraint_id="c1",
                kind=DualSignals.balance,
                sense=DualSignals.eq,
                rhs=0.0,
                unit="MW",
                component_ids=["n1"],
                tags=["core", "balance"],
            ),
            Constraint(
                constraint_id="c2",
                kind=DualSignals.capacity,
                sense=DualSignals.le,
                rhs=100.0,
                unit="MW",
                component_ids=["l1"],
                tags=["limit"],
            ),
        ],
        constraint_solutions=[
            ConstraintSolution(constraint_id="c1", dual=1.5, activity=0.0, slack=0.0),
            ConstraintSolution(constraint_id="c2", dual=2.0, activity=90.0, slack=10.0),
        ],
        variables=[
            VariableValue(component_id="l1", name="flow", value=90.0, unit="MW"),
        ],
    )
    @test isvalid_dataset(dataset)

    json_str = to_json_string(dataset; pretty=true)
    parsed = JSON3.read(json_str, DualSignalsDataset)
    @test isvalid_dataset(parsed)
    @test parsed.dataset_id == "demo"

    mktemp() do path, io
        close(io)
        write_json(path, dataset; pretty=true)
        reloaded = read_json(path)
        @test isvalid_dataset(reloaded)
        @test reloaded.components[1].component_id == "n1"
    end

    mktempdir() do dir
        write_csv(dataset, dir)
        loaded = read_csv(dir)
        @test isvalid_dataset(loaded)
        @test loaded.dataset_id == "demo"
        @test loaded.constraints[1].tags == ["core", "balance"]
    end
end

@testset "DualSignals validation errors" begin
    dataset = build_valid_dataset()
    dataset = DualSignalsDataset(
        dataset_id="",
        metadata=dataset.metadata,
        components=dataset.components,
        constraints=dataset.constraints,
        constraint_solutions=dataset.constraint_solutions,
        variables=dataset.variables,
    )
    errors = validate_dataset(dataset)
    @test any(contains.(errors, "dataset_id"))

    unitless = build_valid_dataset()
    unitless = DualSignalsDataset(
        dataset_id=unitless.dataset_id,
        metadata=DatasetMetadata(description="demo dataset"),
        components=unitless.components,
        constraints=unitless.constraints,
        constraint_solutions=unitless.constraint_solutions,
        variables=unitless.variables,
    )
    unitless_errors = validate_dataset(unitless; require_units=true)
    @test any(contains.(unitless_errors, "units_convention"))

    dup_components = [
        Component(component_id="n1", component_type=DualSignals.node),
        Component(component_id="n1", component_type=DualSignals.node),
    ]
    dup_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=dup_components,
        constraints=Constraint[],
        constraint_solutions=ConstraintSolution[],
        variables=nothing,
    )
    dup_errors = validate_dataset(dup_dataset)
    @test any(contains.(dup_errors, "Duplicate component_id"))

    bad_constraint = Constraint(
        constraint_id="c_bad",
        kind=DualSignals.capacity,
        sense=DualSignals.le,
        rhs=10.0,
        component_ids=String[],
    )
    bad_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=[Component(component_id="n1", component_type=DualSignals.node)],
        constraints=[bad_constraint],
        constraint_solutions=ConstraintSolution[],
        variables=nothing,
    )
    bad_errors = validate_dataset(bad_dataset)
    @test any(contains.(bad_errors, "must reference at least one component_id"))

    missing_component_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=[Component(component_id="n1", component_type=DualSignals.node)],
        constraints=[
            Constraint(
                constraint_id="c1",
                kind=DualSignals.balance,
                sense=DualSignals.eq,
                rhs=0.0,
                component_ids=["n2"],
            ),
        ],
        constraint_solutions=ConstraintSolution[],
        variables=nothing,
    )
    missing_component_errors = validate_dataset(missing_component_dataset)
    @test any(contains.(missing_component_errors, "references missing component_id"))

    missing_constraint_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=[Component(component_id="n1", component_type=DualSignals.node)],
        constraints=Constraint[],
        constraint_solutions=[ConstraintSolution(constraint_id="c1", dual=1.0)],
        variables=nothing,
    )
    missing_constraint_errors = validate_dataset(missing_constraint_dataset)
    @test any(contains.(missing_constraint_errors, "references missing constraint_id"))

    missing_variable_component_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=[Component(component_id="n1", component_type=DualSignals.node)],
        constraints=Constraint[],
        constraint_solutions=ConstraintSolution[],
        variables=[VariableValue(component_id="n2", name="flow", value=1.0)],
    )
    missing_variable_component_errors = validate_dataset(missing_variable_component_dataset)
    @test any(contains.(missing_variable_component_errors, "variable_value references missing component_id"))
end

@testset "Enum and DateTime parsing" begin
    json = """
    {
      "dataset_id": "demo",
      "metadata": { "created_at": "2024-01-01T00:00:00" },
      "components": [
        { "component_id": "n1", "component_type": "node" }
      ],
      "constraints": [
        {
          "constraint_id": "c1",
          "kind": "balance",
          "sense": "eq",
          "component_ids": ["n1"]
        }
      ],
      "constraint_solutions": [
        { "constraint_id": "c1", "dual": 1.0 }
      ],
      "variables": null
    }
    """
    parsed = JSON3.read(json, DualSignalsDataset)
    @test parsed.metadata.created_at isa DateTime
    @test parsed.components[1].component_type == DualSignals.node

    bad_json = """
    {
      "dataset_id": "demo",
      "metadata": {},
      "components": [
        { "component_id": "n1", "component_type": "not_a_type" }
      ],
      "constraints": [],
      "constraint_solutions": []
    }
    """
    @test_throws ErrorException JSON3.read(bad_json, DualSignalsDataset)
end

@testset "Analysis and reporting" begin
    dataset = build_valid_dataset()
    rows = bindingness(dataset)
    @test length(rows) == length(dataset.constraint_solutions)
    @test haskey(first(rows), :impact)

    ranked = rank_constraints(dataset; metric=:abs_dual, top=2)
    @test length(ranked) == 2
    @test ranked[1].metric >= ranked[2].metric
    @test haskey(first(ranked), :impact)

    agg = aggregate_duals(dataset; by=:kind)
    @test !isempty(agg)

    series_dataset = DualSignalsDataset(
        dataset_id="series",
        metadata=DatasetMetadata(description="series demo", units_convention="units"),
        components=dataset.components,
        constraints=dataset.constraints,
        constraint_solutions=[
            ConstraintSolution(constraint_id="c1", dual=1.0, time="t1"),
            ConstraintSolution(constraint_id="c1", dual=2.0, time="t2"),
        ],
        variables=nothing,
    )
    series = aggregate_duals_series(series_dataset; by=:constraint_id, over=:time)
    @test length(series) == 2

    duration_rank = rank_constraints(series_dataset; metric=:dual_times_binding_duration, top=1)
    @test length(duration_rank) == 1

    slack_rank = rank_constraints(dataset; metric=:dual_times_slack_change, slack_change=0.5, top=1)
    @test length(slack_rank) == 1

    table = table_top_constraints(dataset; top=1)
    @test length(table) == 1

    summary = narrative_top_bottlenecks(dataset; top=2)
    @test occursin("Top bottlenecks", summary) || occursin("No binding", summary)

    policy = table_policy_priorities(dataset; top=1)
    @test haskey(policy, :bottlenecks)
    @test haskey(policy, :capacity_expansions)

    policy_text = narrative_policy_summary(dataset; top=1)
    @test occursin("Policy summary", policy_text)

    policy_with_impact = table_policy_priorities(dataset; top=1, with_impact=true)
    @test haskey(policy_with_impact, :bottlenecks)
    @test haskey(policy_with_impact, :capacity_expansions)
    @test haskey(first(policy_with_impact.bottlenecks), :impact)

    policy_extended = table_policy_priorities(
        dataset;
        top=1,
        include_duration=true,
        include_slack_change=true,
        slack_change=0.5,
    )
    @test haskey(policy_extended, :time_weighted_bottlenecks)
    @test haskey(policy_extended, :relaxation_value)

    policy_text_extended = narrative_policy_summary(
        dataset;
        top=1,
        include_duration=true,
        include_slack_change=true,
        slack_change=0.5,
    )
    @test occursin("Time-weighted", policy_text_extended) || occursin("Relaxation value", policy_text_extended)
end
