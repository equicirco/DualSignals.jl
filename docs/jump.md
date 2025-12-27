---
title: JuMP Adapter
nav_order: 6
---

# JuMP adapter

The JuMP adapter converts a solved JuMP model into the DualSignals data model.
It is intentionally conservative and focuses on scalar constraints with duals.

## Function

`jump_dataset(model; dataset_id="jump_model", include_variables=true, include_constraints=true, include_constraint_solutions=true, kind_hint=_default_kind_hint, tag_hint=_default_tag_hint)`

### What it does

- Creates one `Component` per JuMP variable.
- Creates `Constraint` entries for scalar `<=`, `>=`, and `==` constraints.
- Uses `JuMP.dual` for dual values when available.
- Stores variable values as `VariableValue` entries.

Constraint kinds are inferred from constraint names (e.g., `balance`, `cap`,
`limit`, `policy`). You can provide a custom `kind_hint` function to override
the defaults. Constraint tags are supported via `tag_hint(label, kind)` to
attach additional grouping labels (by default no tags are added).

## Limitations

- Only scalar constraints are mapped (vector/PSD constraints are skipped).
- No automatic units; set `units_convention` manually if needed.
- Constraint component mapping uses variables in the constraint body.

## Example

```julia
using JuMP
using DualSignals
import HiGHS

model = Model(HiGHS.Optimizer)
@variable(model, x >= 0)
@variable(model, y >= 0)
@constraint(model, c1, x + y <= 10)
@objective(model, Min, x + 2y)
optimize!(model)

dataset = jump_dataset(model; dataset_id="simple_jump")
```
