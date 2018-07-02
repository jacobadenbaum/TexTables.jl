# Overview
These sections are for advanced users who are interested in fine-tuning
their own custom tables or integrating `TexTables` into their packages.

# Building Tables from Scratch
The core object when constructing tables with `TexTables` is the
`TableCol` type.  This is just a wrapper around an `OrderedDict` and a
header index, that enforces conversion of the header and the keys to
a special multi-index type that work with the `TexTables` structure for
printing.

Let's make up some data (values, keys, and standard errors) so that we
can see all of the different ways to construct columns:
```julia
julia> srand(1234);

julia> vals  = randn(10)
10-element Array{Float64,1}:
  0.867347
 -0.901744
 -0.494479
 -0.902914
  0.864401
  2.21188
  0.532813
 -0.271735
  0.502334
 -0.516984

julia> key  = [Symbol(:key, i) for i=1:10];

julia> se  = randn(10) .|> abs .|> sqrt
10-element Array{Float64,1}:
 0.748666
 0.138895
 0.357861
 1.36117
 0.909815
 0.331807
 0.501174
 0.608041
 0.268545
 1.22614
```

## Constructing Columns From Vectors:

If your data is already in vector form, the easiest way to construct a
`TableCol` is to just pass the vectors as positional arguments:

```julia
julia> t1 = TableCol("Column", key, vals)
      | Column
---------------
 key1 |  0.867
 key2 | -0.902
 key3 | -0.494
 key4 | -0.903
 key5 |  0.864
 key6 |  2.212
 key7 |  0.533
 key8 | -0.272
 key9 |  0.502
key10 | -0.517

julia> typeof(t1)
TexTables.TableCol{1,1}
```

We can also build it iteratively by constructing an empty `TableCol`
object and populating it in a loop:
```julia
julia>  t2 = TableCol("Column")
IndexedTable{1,1} of size (0, 1)

julia>  for (k, v) in zip(key, vals)
            t2[k] = v
        end

julia> t2 == t1
true
```
## Constructing Columns with Standard Errors
To include standard errors, we can either pass the column of standard
errors as a third column, or we can set the index using tuples of `(key,
value)` pairs

```julia
julia>  t3 = TableCol("Column 2");

julia>  for (k, v, p) in zip(key, vals, se)
            t3[k] = v, p
        end

julia> t3
      | Column 2
-----------------
 key1 |    0.867
      |  (0.749)
 key2 |   -0.902
      |  (0.139)
 key3 |   -0.494
      |  (0.358)
 key4 |   -0.903
      |  (1.361)
 key5 |    0.864
      |  (0.910)
 key6 |    2.212
      |  (0.332)
 key7 |    0.533
      |  (0.501)
 key8 |   -0.272
      |  (0.608)
 key9 |    0.502
      |  (0.269)
key10 |   -0.517
      |  (1.226)

julia> t3 == TableCol("Column 2", key,vals, se)
true
```
## Constructing Columns from `<: Associative`
You can also pass an `Associative` of `key=>value` pairs like a `Dict` or
an `OrderedDict`.  Beware though of using `Dict` types to pass the data,
since they will not maintain insertion order:

```julia
julia> dict  = Dict(Pair.(key, vals));
julia> dict2 = OrderedDict(Pair.(key, vals));
julia> TableCol("Column", dict) == TableCol("Column",dict2)
false
```

To pass standard errors in an `Associative` as well, you can either pass
an associative where the values are tuples, or you can pass two
different lookup tables:

```julia
julia> se_dict1= OrderedDict(Pair.(key, tuple.(vals, se)));
julia> se_dict2= OrderedDict(Pair.(key, se));
julia> t3 == TableCol("Column 2",dict2, se_dict2) == TableCol("Column 2", se_dict1)
true
```

# Integrating `TexTables` into your own Estimation Package

Once you know how you would like your model's regression tables to look, it is
extremely easy to built it with `TexTables`.  For instance, the code to
integrate `TexTables` with some of the basic StatsModels.jl
`LinearModel` types is extremely short, and quite instructive to
examine:
```julia

varnames(m::LinearModel) = m.pp.X
varnames(m::DataFrameRegressionModel) = coefnames(m.mf)

tt(m::LinearModel)                  = coef(m) ./ stderror(m)
tt(m::DataFrameRegressionModel)     = coef(m) ./ stderror(m)
pval(m::LinearModel)                = ccdf.(FDist(1, dof_residual(m)),
                                            abs2.(tt(m)))
pval(m::DataFrameRegressionModel)   = ccdf.(FDist(1, dof_residual(m)),
                                            abs2.(tt(m)))
```
Here, we just define some easy accessor methods (internal to
`TexTables`).  Once this is done, the actual code to construct the
tables is only 16 lines, and is extremely straightforward:
```julia
function TableCol(header, m::Union{LinearModel, DataFrameRegressionModel}
                  stats=(:N=>Int∘nobs, "\$R^2\$"=>r2))

    coef_block = TableCol(header)
    for (name, val, se, pval) in zip(varnames(m), coef(m), stderror(m),
                                      pval(m))
        coef_block[name] = val, se
        0.05 <  pval <= .1  && star!(coef_block[name], 1)
        0.01 <  pval <= .05 && star!(coef_block[name], 2)
                pval <= .01 && star!(coef_block[name], 3)
    end

    stats_pairs = OrderedDict(p.first=>p.second(m) for p in stats)
    stats_block = TableCol(header, stats_pairs)

    return append_table(coef_block, stats_block)
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

## A word of caution about merging tables

Be careful when you are stacking tables: `TexTables` does not stack them
positionally.  It merges them on the the appropriate column or row keys.

So suppose we were constructing a summary statistics table by computing
each column and concatenating them together:
```julia
using RDatasets, TexTables, DataStructures, DataFrames
df = dataset("datasets", "attitude")

# Compute summary stats for each variable
cols = []
for header in names(df)
    x = df[header]
    stats = TableCol(header,
                     "N"     => length(x),
                     "Mean"  => mean(x),
                     "Std"   => std(x),
                     "Min"   => minimum(x),
                     "Max"   => maximum(x))
    push!(cols, stats)
end
```
The right way to put them together horizontally is by calling `hcat`:
```julia
julia> tab = hcat(cols[1], cols[2])
     | Rating | Complaints
---------------------------
   N |     30 |         30
Mean | 64.633 |     66.600
 Std | 12.173 |     13.315
 Min |     40 |         37
 Max |     85 |         90
```
But if instead we tried to vertically concatenate them, we would not
simply stack the tables the way you might expect.  `TexTables` will
merge the two columns vertically on their column indexes, which in this
case are _different_.
```julia
julia> [cols[1]; cols[2]]
     | Rating | Complaints
---------------------------
   N | 30     |
Mean | 64.633 |
 Std | 12.173 |
 Min | 40     |
 Max | 85     |
   N |        | 30
Mean |        | 66.600
 Std |        | 13.315
 Min |        | 37
 Max |        | 90
```
This result, while perhaps unintuitive, is by design.  `cols[1]` and
`cols[2]` really are not of a shape that could be put together
vertically (at least not without overwriting one of their column names).
But rather than give an error when some keys are not present,
`TexTables` tries it's best to put them together in the order you've
requested.  This behavior is essential for horizontally concatenating
two regression tables with summary statistics blocks at the bottom.
In general, whenever you concatenate two tables, they need to have the
same structure in the dimension that they are not being joined upon, or
the results will probably not be what you expected.
