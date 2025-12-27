---
title: "Example: OPF"
nav_order: 10
---

# IEEE 14-bus OPF example

This example uses the classic IEEE 14-bus optimal power flow (OPF) test case.
The IEEE 14-bus case is a small, widely used benchmark power network with a
handful of generators, loads, and transmission lines, which makes it ideal for
checking dual values, binding limits, and nodal price patterns in a realistic
yet tractable setting.

## Data source

The dual solution for this example is taken from the PGLearn dataset collection:

- PGLearn Datasets, "PGLearn Optimal Power Flow (small)", https://huggingface.co/datasets/PGLearn/PGLearn-Small

For this IEEE 14-bus example we use a single dual sample from:

- `14_ieee/test/ACOPF/dual.h5.gz` in the PGLearn-Small dataset

The extracted sample (in the DualSignals data model) lives in this repository at:

- `examples/case14_IEEE/dualsignals_dual_sample_1.json`

Direct download URL for the source file:

- https://huggingface.co/datasets/PGLearn/PGLearn-Small/resolve/main/14_ieee/test/ACOPF/dual.h5.gz

## How this example was derived

The original dual file is an HDF5 archive with many samples. We extracted the
first sample (index 1) and mapped each dual vector to constraints in the
DualSignals schema:

- `kcl_p`, `kcl_q` -> bus balance constraints (`ConstraintKind.balance`, `ConstraintSense.eq`)
- `vm` -> bus voltage magnitude limits (`ConstraintKind.capacity`, `ConstraintSense.le`)
- `pg`, `qg` -> generator limits (`ConstraintKind.capacity`, `ConstraintSense.le`)
- `pf`, `pt`, `qf`, `qt`, `sm_fr`, `sm_to` -> line flow/thermal limits (`ConstraintKind.capacity`, `ConstraintSense.le`)
- `va_diff`, `ohm_pf`, `ohm_pt`, `ohm_qf`, `ohm_qt` -> physics constraints (`ConstraintKind.other`, `ConstraintSense.eq`)
- `slack_bus` -> slack constraint for bus 1 (`ConstraintKind.other`, `ConstraintSense.eq`)

Components were created for each bus, generator, and line using the counts in
the HDF5 arrays (14 buses, 5 generators, 20 lines). This yields a dual-only
dataset suitable for constraint ranking and bindingness analysis.

## Computed results (DualSignals.jl)

Summary:
- components: 39
- constraints: 273
- constraint solutions: 273

Because this dataset does not include binding flags or slack values, the tables
below show the top constraints by `|dual|` without filtering to binding-only.

### Top constraints by |dual|

| constraint_id | kind     | sense | dual        | impact                            |
| ------------- | -------- | ----- | ----------- | --------------------------------- |
| vm_8          | capacity | le    | -15499.9863 | impact depends on objective sense |
| kcl_q_1       | balance  | eq    | 6112.8657   | impact depends on objective sense |
| qg_1          | capacity | le    | -6112.8657  | impact depends on objective sense |
| ohm_qf_1      | other    | eq    | -6112.8657  | impact depends on objective sense |
| ohm_qf_2      | other    | eq    | -6112.8657  | impact depends on objective sense |

### Top capacity constraints by |dual|

| constraint_id | kind     | sense | dual        | impact                            |
| ------------- | -------- | ----- | ----------- | --------------------------------- |
| vm_8          | capacity | le    | -15499.9863 | impact depends on objective sense |
| qg_1          | capacity | le    | -6112.8657  | impact depends on objective sense |
| qg_2          | capacity | le    | -5987.9224  | impact depends on objective sense |
| qg_3          | capacity | le    | -5639.9927  | impact depends on objective sense |
| qg_4          | capacity | le    | -5119.9336  | impact depends on objective sense |

### Plot: top |dual| constraints

```text
vm_8                   | ############################ 15499.9863
kcl_q_1                | ########### 6112.8657
qg_1                   | ########### 6112.8657
ohm_qf_1               | ########### 6112.8657
ohm_qf_2               | ########### 6112.8657
```

## Reproducing the tables and plot

```julia
using DualSignals

dataset = read_json("examples/case14_IEEE/dualsignals_dual_sample_1.json")
top = rank_constraints(dataset; top=5, binding_only=false, metric=:abs_dual)
top_capacity = rank_constraints(dataset; top=5, binding_only=false, metric=:abs_dual,
    kind=DualSignals.capacity)
```
