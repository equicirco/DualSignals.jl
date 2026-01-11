```@raw html
<img src="assets/logo.png" alt="DualSignals.jl logo" width="120" style="vertical-align: middle;">
<img src="assets/logo-light.png" alt="DualSignals.jl logo (light)" width="120" style="vertical-align: middle;">
<img src="assets/logo-dark.png" alt="DualSignals.jl logo (dark)" width="120" style="vertical-align: middle;">
```

# DualSignals.jl
Julia package for standardized extraction and decision-support reporting of shadow prices (duals) and constraint tightness from network and equilibrium models.

## Project info

- Source code: [https://github.com/equicirco/DualSignals.jl](https://github.com/equicirco/DualSignals.jl)
- License: [https://github.com/equicirco/DualSignals.jl/blob/main/LICENSE](https://github.com/equicirco/DualSignals.jl/blob/main/LICENSE)
- Author: Riccardo Boero
- Citation (DOI): [https://doi.org/10.5281/zenodo.18071806](https://doi.org/10.5281/zenodo.18071806)

```bibtex
@software{Boero_DualSignals_jl,
  author = {Boero, Riccardo},
  title = {DualSignals.jl - Julia package for standardized extraction and decision-support reporting of shadow prices (duals) and constraint tightness from network and equilibrium models},
  doi = {10.5281/zenodo.18071806},
  url = {https://equicirco.github.io/DualSignals.jl/},
  year = {2025}
}
```

## Installation
DualSignals.jl is available as a package from the Julia General Registry:
```julia
using Pkg
Pkg.add("DualSignals")
```

## What this package does

DualSignals.jl helps you turn solved optimization and equilibrium models into
decision-ready insights. It provides:

- A compact data model for duals, constraints, and components.
- IO utilities to read/write JSON and tabular exports.
- Validation utilities to check consistency of exported results.
- Analysis helpers for ranking bottlenecks and capacity priorities.
- Reporting utilities that summarize results for non-experts.

## Documentation map

- Data model specification: [Data Model](data-model.md)
- Read/write and validation utilities: [Data IO](io.md)
- Analysis helpers: [Analysis](analysis.md)
- Reporting utilities: [Reporting](reporting.md)
- JuMP adapter: [JuMP Adapter](jump.md)
- Notebook walkthroughs: [Notebooks](notebooks.md)
- Examples: [IEEE-14 OPF](example-ieee14-opf.md) and [CGE](stdcge.md)
