<img src="docs/src/assets/logo.png" alt="DualSignals.jl logo" width="120" style="vertical-align: middle;">
<img src="docs/src/assets/logo-light.png" alt="DualSignals.jl logo (light)" width="120" style="vertical-align: middle;">
<img src="docs/src/assets/logo-dark.png" alt="DualSignals.jl logo (dark)" width="120" style="vertical-align: middle;">

# DualSignals.jl
Julia package for standardized extraction and decision-support reporting of shadow prices (duals) and constraint tightness from network and equilibrium models.

DualSignals.jl standardizes extraction and decision-support reporting of dual variables (shadow prices / Lagrange multipliers) and constraint tightness from solved optimization and equilibrium models. It is designed to work across networked infrastructures and general equilibrium applications by using a simple, portable data model: **components ⇄ constraints ⇄ duals**.

## Approach
1. Export model results into the DualSignals data model (constraints, duals, activity/slack, units, component mapping).
2. Run generic analyses (bindingness, bottleneck rankings, marginal values of relaxations).
3. Produce decision-support outputs (tables and concise narratives) suitable for non-expert audiences.

## Documentation
Documentation is available here: https://equicirco.github.io/DualSignals.jl

## Installation
DualSignals.jl is available as a package from the Julia General Registry:
```julia
using Pkg
Pkg.add("DualSignals")
```

## Citation
If you use DualSignals.jl, please cite it as:

```bibtex
@software{Boero_DualSignals_jl,
  author = {Boero, Riccardo},
  title = {DualSignals.jl - Julia package for standardized extraction and decision-support reporting of shadow prices (duals) and constraint tightness from network and equilibrium models},
  doi = {10.5281/zenodo.18071806},
  url = {https://equicirco.github.io/DualSignals.jl/},
  year = {2025}
}
```

## License
MIT License. See [`LICENSE`](LICENSE).

## Author
Riccardo Boero (ribo@nilu.no)



