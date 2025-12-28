# Standard CGE Model

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

## Computed results (DualSignals.jl)

Summary:
- components: 13
- constraints: 47
- constraint solutions: 47

Because this dataset does not include binding flags or slack values, the tables
below show the top constraints by `|dual|` without filtering to binding-only.

### Top constraints by |dual|

| constraint_id | kind  | sense | dual    | impact                            |
| ------------- | ----- | ----- | ------- | --------------------------------- |
| eqpm_BRD      | other | eq    | 1.6865  | impact depends on objective sense |
| eqpzs_BRD     | other | eq    | 1.5421  | impact depends on objective sense |
| eqpzs_MLK     | other | eq    | -1.5090 | impact depends on objective sense |
| eqpm_MLK      | other | eq    | 1.0466  | impact depends on objective sense |
| obj           | other | eq    | 1.0000  | impact depends on objective sense |

### Top capacity constraints by |dual|

No capacity constraints are present in this dataset.

### Plot: top |dual| constraints

```text
eqpm_BRD               | ############################ 1.6865
eqpzs_BRD              | ########################## 1.5421
eqpzs_MLK              | ######################### 1.5090
eqpm_MLK               | ################# 1.0466
obj                    | ################# 1.0000
```

## Reproducing the tables and plot

```julia
using DualSignals

dataset = read_json("examples/stdcge/dualsignals_stdcge.json")
top = rank_constraints(dataset; top=5, binding_only=false, metric=:abs_dual)
top_capacity = rank_constraints(dataset; top=5, binding_only=false, metric=:abs_dual,
    kind=DualSignals.capacity)
```
