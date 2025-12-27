---
title: IEEE 14-Bus OPF Example
nav_order: 4
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

## Representing the solution in the DualSignals data model

TODO: map buses/lines/generators to `Component` entries and OPF constraints to
`Constraint` and `ConstraintSolution` entries.

## Running DualSignals.jl on the example

TODO: add a Julia snippet that loads the JSON, validates it, and runs the
analysis utilities (bindingness and rankings).
