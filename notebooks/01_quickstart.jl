### A Pluto.jl notebook ###
# v0.19.46

using Markdown

# ╔═╡ 7a2e27d2-7a12-4f3c-8f2f-9c8f4d6b0a01
md"""
# DualSignals Quickstart

Structure:
1. Load data
2. Validate
3. Tables
4. Graphs
5. Narrative summary
"""

# ╔═╡ 1a1f42f9-979a-4d2b-8a06-05d1f89aa0a4
using DualSignals

# ╔═╡ 5b9b5f8f-1b8f-4c40-9f04-0b1b6a5d31d5
md"## Load data"

# ╔═╡ 2f7c21a0-16c9-47b3-85c1-3aa6c0f4b2cf
dataset = DualSignalsDataset(
    dataset_id="demo",
    metadata=DatasetMetadata(description="quickstart demo", units_convention="units"),
    components=[
        Component(component_id="c1", component_type=DualSignals.node, name="Component 1"),
        Component(component_id="c2", component_type=DualSignals.link, name="Component 2"),
    ],
    constraints=[
        Constraint(
            constraint_id="k1",
            kind=DualSignals.balance,
            sense=DualSignals.eq,
            rhs=0.0,
            unit="MW",
            component_ids=["c1"],
        ),
        Constraint(
            constraint_id="k2",
            kind=DualSignals.capacity,
            sense=DualSignals.le,
            rhs=100.0,
            unit="MW",
            component_ids=["c2"],
        ),
    ],
    constraint_solutions=[
        ConstraintSolution(constraint_id="k1", dual=1.2, activity=0.0, slack=0.0),
        ConstraintSolution(constraint_id="k2", dual=3.5, activity=95.0, slack=5.0),
    ],
    variables=[
        VariableValue(component_id="c2", name="flow", value=95.0, unit="MW"),
    ],
)

# ╔═╡ 3e422bb8-845f-4e05-8cb8-6a7e3b2c7d46
md"## Validation"

# ╔═╡ 2d9ac4ef-76f6-4c8a-9d44-2448d0045161
validation_errors = validate_dataset(dataset)

# ╔═╡ c74c3cc0-2fe4-4f8d-9e75-5b9677c8b1df
validation_errors

# ╔═╡ 0b0f35f2-2a65-49b8-aed3-2fba7b2b7348
md"## Tables"

# ╔═╡ 64bb0c61-4b10-4e2d-99d1-9d4a0a3d6a58
top = table_policy_priorities(dataset; top=5, with_impact=true)

# ╔═╡ 9c9e0d66-1b39-47ac-b27c-8d60a1f9b0d9
top

# ╔═╡ 7c19e0f2-6407-4e25-85fa-0cf2f27fca61
md"## Graphs (optional)"

# ╔═╡ e31b6294-b733-4f3f-a6a2-7a5c2c0f03b6
function maybe_bar(labels, values; title="")
    try
        @eval import UnicodePlots
        return UnicodePlots.barplot(labels, values; title=title)
    catch
        return "Install UnicodePlots.jl to enable simple charts."
    end
end

# ╔═╡ 7ab3b0b7-7f6c-4fd8-90e9-c4b274e44e55
labels = [row.constraint_id for row in top.bottlenecks]

# ╔═╡ a4b9f5e2-7ae4-4a73-98bb-5d9f3c2a1c0f
values = [abs(row.dual) for row in top.bottlenecks]

# ╔═╡ 2f6aa015-69b7-4c84-9792-88f4c4b22a3c
maybe_bar(labels, values; title="Top bottlenecks (|dual|)")

# ╔═╡ 06f7e7f1-6030-4b77-a6a9-5f09a6a67f40
md"## Narrative"

# ╔═╡ 3f9bd7d6-7c6e-4d18-8f50-7b8c1767f3a0
narrative_policy_summary(dataset; top=3)
