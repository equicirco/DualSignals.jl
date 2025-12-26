using Test
using DualSignals
using JSON3

function build_valid_dataset()
    metadata = DatasetMetadata(description="demo dataset")
    components = [
        Component(component_id="n1", component_type=ComponentType.node, name="Node 1"),
        Component(component_id="l1", component_type=ComponentType.link, name="Link 1"),
    ]
    constraints = [
        Constraint(
            constraint_id="c1",
            kind=ConstraintKind.balance,
            sense=ConstraintSense.eq,
            rhs=0.0,
            component_ids=["n1"],
        ),
        Constraint(
            constraint_id="c2",
            kind=ConstraintKind.capacity,
            sense=ConstraintSense.le,
            rhs=100.0,
            component_ids=["l1"],
        ),
    ]
    solutions = [
        ConstraintSolution(constraint_id="c1", dual=1.5, activity=0.0, slack=0.0),
        ConstraintSolution(constraint_id="c2", dual=2.0, activity=90.0, slack=10.0),
    ]
    variables = [
        VariableValue(component_id="l1", name="flow", value=90.0, unit="MW"),
    ]

    return DualSignalsDataset(
        dataset_id="demo",
        metadata=metadata,
        components=components,
        constraints=constraints,
        constraint_solutions=solutions,
        variables=variables,
    )
end

@testset "DualSignals serialization" begin
    dataset = build_valid_dataset()
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

    dup_components = [
        Component(component_id="n1", component_type=ComponentType.node),
        Component(component_id="n1", component_type=ComponentType.node),
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
        kind=ConstraintKind.capacity,
        sense=ConstraintSense.le,
        rhs=10.0,
        component_ids=String[],
    )
    bad_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=[Component(component_id="n1", component_type=ComponentType.node)],
        constraints=[bad_constraint],
        constraint_solutions=ConstraintSolution[],
        variables=nothing,
    )
    bad_errors = validate_dataset(bad_dataset)
    @test any(contains.(bad_errors, "must reference at least one component_id"))

    missing_component_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=[Component(component_id="n1", component_type=ComponentType.node)],
        constraints=[
            Constraint(
                constraint_id="c1",
                kind=ConstraintKind.balance,
                sense=ConstraintSense.eq,
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
        components=[Component(component_id="n1", component_type=ComponentType.node)],
        constraints=Constraint[],
        constraint_solutions=[ConstraintSolution(constraint_id="c1", dual=1.0)],
        variables=nothing,
    )
    missing_constraint_errors = validate_dataset(missing_constraint_dataset)
    @test any(contains.(missing_constraint_errors, "references missing constraint_id"))

    missing_variable_component_dataset = DualSignalsDataset(
        dataset_id="demo",
        metadata=DatasetMetadata(),
        components=[Component(component_id="n1", component_type=ComponentType.node)],
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
    @test parsed.components[1].component_type == ComponentType.node

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
