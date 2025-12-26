---
title: Data Model
nav_order: 2
---

# DualSignals data model (LinkML)

This repository defines a small, model-agnostic data model for exporting and exchanging **dual-based signals** from solved models (network optimization, IO-LP, equilibrium/CGE-as-optimization, etc.). The same model is maintained in:

- **LinkML** (`spec/linkml/dualsignals.yaml`) as the canonical specification
- **JSON Schema** (`spec/schema/dualsignals.schema.json`) generated from LinkML for validation and exchange

## Concept
The core idea is to standardize results around three primitives:

1. **Components**: the “things” you want to talk about (nodes, links, sources, sinks, sectors, products, agents, …).
2. **Constraints**: the model restrictions that refer to components (balances, capacities, resource limits, policy caps, technology limits, …).
3. **Constraint solutions**: the solved information attached to constraints (dual/shadow price, activity, slack, binding status), optionally indexed by time and scenario.

This is sufficient to compute generic decision-support outputs such as:
- which constraints are binding,
- which bottlenecks have the highest marginal value of relaxation (largest |dual|),
- which capacities are most valuable to expand (capacity-kind constraints with high dual),
- nodal price spreads (when balance constraints produce nodal shadow prices).

## Top-level object

All exchanges use a single JSON object of class `DualSignalsDataset` with keys:

- `dataset_id` (required)
- `metadata` (required)
- `components` (required, list)
- `constraints` (required, list)
- `constraint_solutions` (required, list)
- `variables` (optional, list)

## Classes

### DatasetMetadata
Describes the dataset and optional objective context.

Fields:
- `description` (optional): free text
- `created_at` (optional): timestamp
- `objective_sense` (optional): `minimize` or `maximize`
- `objective_value` (optional): objective value at the solution
- `units_convention` (optional): note on units/currency conventions used
- `notes` (optional): free text

### Component
Defines the entities in your model.

Fields:
- `component_id` (required): unique ID
- `component_type` (required): enum (`node`, `link`, `source`, `sink`, `sector`, `product`, `agent`, `other`)
- `name` (optional): human-readable label
- `parent_id` (optional): for hierarchies (e.g., node → region, product → sector)
- `unit` (optional): primary unit for the component
- `tags` (optional): list of strings for grouping/filtering

### Constraint
Defines a model constraint and which components it relates to.

Fields:
- `constraint_id` (required): unique ID
- `kind` (required): enum (`balance`, `capacity`, `resource`, `policy_cap`, `technology`, `other`)
- `sense` (required): enum (`le`, `eq`, `ge`)
- `rhs` (optional): right-hand-side / bound value (numeric)
- `unit` (optional): unit of the constraint (e.g., MW, tCO2)
- `component_ids` (required): list of component IDs referenced by the constraint

Notes:
- `component_ids` can have 1 entry (e.g., a node balance) or multiple entries (e.g., a constraint involving a set of components).
- For link capacities, `component_ids` typically includes the link component ID.

### ConstraintSolution
Stores solved quantities attached to a constraint (the “signals”).

Fields:
- `constraint_id` (required): reference to `Constraint` (by ID)
- `dual` (required): the dual variable / shadow price / Lagrange multiplier
- `activity` (optional): realized LHS value at the solution
- `slack` (optional): slack for inequalities (0 if binding)
- `is_binding` (optional): boolean flag (if precomputed)
- `time` (optional): ISO-8601 timestamp or period label (e.g., `"2025-01"`, `"t=12"`)
- `scenario` (optional): scenario/policy identifier

Notes:
- `dual` is interpreted as the marginal objective change for a marginal relaxation of the associated constraint, consistent with the model’s objective sense and constraint sense. Record units explicitly.

### VariableValue (optional)
Stores component-level primal outputs (flows, injections, outputs) to support richer reporting.

Fields:
- `component_id` (required): references `Component.component_id`
- `name` (required): variable name (e.g., `flow`, `injection`, `output`)
- `value` (required): numeric value
- `unit` (optional)
- `time` (optional)
- `scenario` (optional)

## Generating JSON Schema from LinkML
CI/CD script makes the JSON Schema automatically but it can also be generated manually:

```bash
python -m pip install -U linkml linkml-runtime

linkml-generate jsonschema \
  --no-metadata \
  -s spec/linkml/dualsignals.yaml \
  > spec/schema/dualsignals.schema.json
```
