---
title: STDCGE Example
nav_order: 5
---

# STDCGE example (standard CGE model)

This example is based on the "A Standard CGE Model in Ch. 6 (STDCGE, SEQ=276)"
case described in `stdcge.gms` from the `gams-cge` repository. It represents a
small computable general equilibrium model with two goods (BRD, MLK) and two
primary factors (CAP, LAB), calibrated from a social accounting matrix.

## Reference

Hosoe, N, Gasawa, K, and Hashimoto, H  
*Handbook of Computible General Equilibrium Modeling*  
University of Tokyo Press, Tokyo, Japan, 2004

## Source and attribution

Model description and features:
- https://github.com/ounokoya/gams-cge/blob/main/stdcge.gms

Solution and duals (GAMS listing/output files):
- https://github.com/ounokoya/gams-cge/blob/main/stdcge.lst
- https://github.com/ounokoya/gams-cge/blob/main/stdcge.gdx

We extract the solution levels and equation marginals from the repository above,
then map them into the DualSignals data model.

## Derived DualSignals dataset

The DualSignals-formatted output for this example is stored at:

- `examples/stdcge/dualsignals_stdcge.json`

### How the mapping was done

- Variables use the **LEVEL** column from `stdcge.lst` as `VariableValue` entries.
- Equation **MARGINAL** values are used as duals in `ConstraintSolution`.
- Equation and variable indices are preserved and used to create components.
- Scalar equations/variables map to a `scalar` component.

This yields a compact, dual-centric dataset suitable for constraint ranking and
bindingness analysis in DualSignals.jl.
