---
title: Notebooks
nav_order: 8
---

# Pluto notebooks

The `notebooks/` folder contains simple Pluto.jl notebooks with a shared
structure:

1. Load data
2. Validate/verify
3. Tables
4. Graphs
5. Narrative summary

## Available notebooks

- `notebooks/01_quickstart.jl`  
  Minimal demo using an in‑memory dataset.

- `notebooks/02_ieee14_opf.jl`  
  IEEE 14‑bus OPF dual sample from `examples/case14_IEEE/dualsignals_dual_sample_1.json`.

- `notebooks/03_stdcge.jl`  
  STDCGE example from `examples/stdcge/dualsignals_stdcge.json`.

## Usage

1. Start Pluto:

```julia
import Pluto
Pluto.run()
```

2. Open a notebook from the `notebooks/` directory.

## Optional plotting

The notebooks can render simple bar charts if `UnicodePlots.jl` is installed:

```julia
import Pkg
Pkg.add("UnicodePlots")
```

If it is not installed, the notebooks will show a small message instead of a plot.
