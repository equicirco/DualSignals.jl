### A Pluto.jl notebook ###
# v0.19.46

using Markdown

# ╔═╡ 7e2b7f9f-4b41-4e7a-b2b0-1a1a7f5c5a01
md"""
# IEEE 14-bus OPF example

Structure:
1. Load data
2. Validate
3. Tables
4. Graphs
5. Narrative summary
"""

# ╔═╡ 6a09f3b4-7fcb-4f6f-a0a5-454bbd6a1111
using DualSignals

# ╔═╡ 5a8a7c11-2d30-4a42-9d38-602b7aa7d9d3
md"## Load data"

# ╔═╡ 0aa64a8a-7e41-4e1f-8f1f-8293d7fbcb0a
data_path = joinpath(@__DIR__, "..", "examples", "case14_IEEE", "dualsignals_dual_sample_1.json")

# ╔═╡ a25b352d-2a9b-4b1b-9a6d-0f2bc0d8b120
dataset = read_json(data_path)

# ╔═╡ 092e8391-34b8-4c74-8f8a-11a1a3875a26
md"## Validation"

# ╔═╡ 3da7d77a-0f35-4c9b-9237-20265c2bcd02
validation_errors = validate_dataset(dataset)

# ╔═╡ 8863eb38-9e3d-4a59-8e6a-3f416abf8c6f
validation_errors

# ╔═╡ 81b05bf1-09b2-4a5d-8b9b-fc0c33322d71
md"## Tables"

# ╔═╡ 0e7b0f44-2d6c-4af7-9a8a-6f5d0f1d235f
top = table_policy_priorities(dataset; top=10, with_impact=true)

# ╔═╡ 7d79a7cf-87ce-4d6b-8ae2-6e3752c5f6ea
top

# ╔═╡ 3b1ef9a6-83c4-4b37-9a60-9b3de0d30a57
md"## Graphs (optional)"

# ╔═╡ 59f18c9c-0d35-4a87-9f1a-5f1a6d7e4c11
function maybe_bar(labels, values; title="")
    try
        @eval import UnicodePlots
        return UnicodePlots.barplot(labels, values; title=title)
    catch
        return "Install UnicodePlots.jl to enable simple charts."
    end
end

# ╔═╡ 0c1dc6c8-f6f1-4f5a-a0c7-125d0d7f4b82
labels = [row.constraint_id for row in top.bottlenecks][1:min(10, length(top.bottlenecks))]

# ╔═╡ e19d4b3f-1f1b-49fb-b733-4cbe5a67c62a
values = [abs(row.dual) for row in top.bottlenecks][1:min(10, length(top.bottlenecks))]

# ╔═╡ 3e0f1ad0-3b9f-4c5b-8c6b-9d7e1a1c3b09
maybe_bar(labels, values; title="Top bottlenecks (|dual|)")

# ╔═╡ 68fcb227-1b3f-45dc-9e70-1e54c9b1f904
md"## Narrative"

# ╔═╡ 8b680b04-41d0-4d74-9a0a-1f41d43c8435
narrative_policy_summary(dataset; top=5)
