### A Pluto.jl notebook ###
# v0.19.46

using Markdown

# ╔═╡ 3dfd2e9d-6a3f-4d90-b3d5-0b8c45ce9f01
md"""
# STDCGE example

Structure:
1. Load data
2. Validate
3. Tables
4. Graphs
5. Narrative summary
"""

# ╔═╡ 52b41b3f-7d2b-4c51-9e13-0b01d5a9a58f
using DualSignals

# ╔═╡ 0a4b7d8a-4ef2-4bc9-8f4f-8f1f7a2c40a2
md"## Load data"

# ╔═╡ 77f52c3b-2b44-4e8a-bf9b-4c2c3b2895b9
data_path = joinpath(@__DIR__, "..", "examples", "stdcge", "dualsignals_stdcge.json")

# ╔═╡ 3d07ecf1-74a6-4b9f-9e7c-3b0c12c06d5a
dataset = read_json(data_path)

# ╔═╡ 0fa0a4b4-cd6a-4d6f-86f8-1b2bba7e0f1f
md"## Validation"

# ╔═╡ 4c57fb9e-79b7-4d4f-bd55-9c53b037a6bf
validation_errors = validate_dataset(dataset)

# ╔═╡ 299fd5df-4b2b-4b6b-96f4-d3f88dcbf9e2
validation_errors

# ╔═╡ 2b561f16-8b7d-4c50-8b8f-632f9d8f66cd
md"## Tables"

# ╔═╡ d6bcd1f2-b9a7-4f8a-8c42-0d0e6f8f78a3
top = table_policy_priorities(dataset; top=10, with_impact=true)

# ╔═╡ 5a86fe4a-3b20-4ff2-9a1b-8b58c1b2e80b
top

# ╔═╡ 404b6a12-3b6f-4b1b-97f3-1b7cc8657b0a
md"## Graphs (optional)"

# ╔═╡ e3d7cc3f-8b87-4b73-8a4f-1b0c2d9b8f13
function maybe_bar(labels, values; title="")
    try
        @eval import UnicodePlots
        return UnicodePlots.barplot(labels, values; title=title)
    catch
        return "Install UnicodePlots.jl to enable simple charts."
    end
end

# ╔═╡ 6d6b1e3f-4a97-4c2b-9f0c-2f5d5a9c5a29
labels = [row.constraint_id for row in top.bottlenecks][1:min(10, length(top.bottlenecks))]

# ╔═╡ 8c3f5e8a-9c8f-4e3a-9b33-6b2b8f4f1c1c
values = [abs(row.dual) for row in top.bottlenecks][1:min(10, length(top.bottlenecks))]

# ╔═╡ 6f26c7f0-0a1a-4f2d-8c0f-1a0f7d1e8d2e
maybe_bar(labels, values; title="Top bottlenecks (|dual|)")

# ╔═╡ 68a63f7f-4a0f-4d4a-b8b8-9a1f5b6c7d2e
md"## Narrative"

# ╔═╡ 9b6a63d2-4f3d-4b9a-8a4f-7d0b1f2c3a4e
narrative_policy_summary(dataset; top=5)
