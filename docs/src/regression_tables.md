# Regression Tables API

TexTables should be able to provide a basic regression table for any model that
adheres to the `RegressionModel` API found in StatsBase and makes it easy to
customize the tables with additional fit statistics or model information as you
see fit.  This section documents how to use and customize the regression tables
functionality for models in your code, as well as how to override the default
settings for a model in your Package.

## Special Structure of Regression Tables
Regression tables in TexTables are constructed using a special API that is
provided to ensure that the regression tables from different estimators
(potentially from separate packages) can be merged together.  You should _not_
construct your tables directly if you want them to merge nicely with the
standard regression tables.  Instead, you should use the methods documented in
this section.

Regression tables are divided into 3 separate row blocks:
1.  Coefficients: This block contains the parameter estimates and
    standard errors (possibly decorated with stars for p-values) and always
    appears first
2.  Metadata: This block is empty by default (and therefore will not be
    printed in the table), but can be populated by the user to include
    column/model specific metadata.  For example, a user might want to denote
    whether or not they controlled for one of the variables in their data, or
    which estimator they used in each column (OLS/Fixed Effects/2SLS/etc...)
3.  Fit Statistics: This block contains fit statistics.  It defaults to $R^2$
    and the number of observations, but this can be changed by the user.

You can construct sub-blocks within each of these three layers, although this is
turned off by default.  In order to support these three layers and the possible
addition of sublayers, `TableCol`s that conform to this API must be subtypes of
`TableCol{3,M} where M`.  For convenience a typealias `RegCol{M} =
TableCol{3,M}` is provided, along with a constructor for empty `RegCol`s from
just the desired header.

## Adding Each Block

You can construct or add to each of the three blocks using the convenience
methods `setcoef!`, `setmeta!`, and `setstats!`.  All three have an identical
syntax:
```
set[block]!(t::RegCol, key, val[, se]; level=1, name="")
set[block]!(t::RegCol, key=>val; level=1, name="")
set[block]!(t::RegCol, kv::Associative)
```
This will insert into `t` a key/value pair (possibly with a standard error) within
the specified  block.  Like the `TableCol` constructor, the pairs
can be passed as either individual key/value[/se] tuples or pairs, as
several vectors of key/value[/se] pairs, or as an associative.

To add additional sub-blocks, use the `level` keyword argument.  Integers
less than 0 will appears in blocks above the standard block, and integers
greater than 1 will appear below it.

To name the block or sub-block, pass a nonempty string as the `name` keyword
argument.

For instance, if you wanted to construct a regression column with two
coefficients 1.32 (0.89) and -0.21 (0.01), metadata that indicates that the
underlying estimation rotuine used OLS, and an $R^2$ of 0.73, then you would
run the following code:
```jldoctest
col = RegCol("My Column")
setcoef!(col, "Coef 1"=>(1.32, 0.89), "Coef 2"=>(-0.21, 0.01))
setmeta!(col, :Estimator=>"OLS")
setstats!(col, "\$R^2\$"=>0.73)
println(col)

# output
          | My Column
----------------------
   Coef 1 |     1.320
          |   (0.890)
   Coef 2 |    -0.210
          |   (0.010)
----------------------
Estimator |       OLS
----------------------
    $R^2$ |     0.730
```

## Robust Standard Errors
If you would like to overide the standard `stderror` function for your table,
use the `stderror` keyword argument.  For instance, you might want to use the
[CovarianceMatrices](https://github.com/gragusa/CovarianceMatrices.jl) package
to compute robust standard errors.  In this case, you would simply define a new
function
```julia
using CovarianceMatrices
robust(m) = stderror(m, HC0)
TableCol("My Column", m; stderror=robust)
```
Note: This feature is relatively experimental and its usage may change in future
releases.

## Integrating `TexTables` into your own Estimation Package

Once you know how you would like your model's regression tables to look, it is
extremely easy to built it with `TexTables`.  For instance, the code to
integrate `TexTables` with some of the basic StatsModels.jl `RegressionModel`
types is extremely short, and quite instructive to examine:
```julia
function TableCol(header, m::RegressionModel;
                  stats=(:N=>Int∘nobs, "\$R^2\$"=>r2),
                  meta=(), stderror::Function=stderror, kwargs...)

    # Compute p-values
    pval(m) = ccdf.(FDist(1, dof_residual(m)),
                    abs2.(coef(m)./stderror(m)))

    # Initialize the column
    col  = RegCol(header)

    # Add the coefficients
    for (name, val, se, p) in zip(coefnames(m), coef(m), stderror(m), pval(m))
        addcoef!(col, name, val, se)
        0.05 <  p <= .1  && star!(col[name], 1)
        0.01 <  p <= .05 && star!(col[name], 2)
                p <= .01 && star!(col[name], 3)
    end

    # Add in the fit statistics
    addstats!(col, OrderedDict(p.first=>p.second(m) for p in stats))

    # Add in the metadata
    addmeta!(col, OrderedDict(p.first=>p.second(m) for p in meta))

    return col
end
```
Here, we
1. Constructed an empty column with the header value passed by the user
2. Looped through the coefficients, their names, their standard
   errors, and their pvalues.  On each iteration, we:

   a.  Insert the coefficient value and its standard error into the table

   b.  Check whether the p-values fall below the desired threshold (in
       descending order), and if so, call the function
       `star!(x::FormattedNumber, num_stars)` with the desired number of
       stars.

`TexTables` stores all of the table values internally with a
`FormattedNumber` type, which contains the value, the standard error if
appropriate, the number of stars the value should display, and a
formatting string.  As a result, it is probably easiest to set the table
value first, and then add stars later with the `star!` function.
However, we could also have constructed each value directly as:
```julia
if .05 < pval <= .1
    coef_block[name] = val, se, 1
elseif 0.01 < pval <= .05
    coef_block[name] = val, se, 2
elseif pval <= .01
    coef_block[name] = val, se, 3
end
```
How you choose to do it is mostly a matter of taste and coding style.
Note that by default, the number of stars is always set to zero.  In
other words, `TexTables` will _not_ assume that it can infer the number
of significance stars from the standard errors and the coefficients
alone.  If you want to annotate your table with significance stars, you
must explicitly choose in your model-specific code which entries to
annotate and how many stars they should have.

