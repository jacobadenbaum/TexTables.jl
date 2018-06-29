# TexTables.jl

[![Build Status](https://travis-ci.org/jacobadenbaum/TexTables.jl.svg?branch=master)](https://travis-ci.org/jacobadenbaum/TexTables.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/5a5w5ucqscscr5bl?svg=true)](https://ci.appveyor.com/project/jacobadenbaum/textables-jl)
[![Coverage Status](https://coveralls.io/repos/github/jacobadenbaum/TexTables.jl/badge.svg?branch=master)](https://coveralls.io/github/jacobadenbaum/TexTables.jl?branch=master)

The TexTable package provides an easy way for Julia users to quickly
build well-formated and publication-ready ASCII and LaTeX tables from a
variety of different data structures.  It allows the user to easily
build complex tables from small, modular components in an object
oriented fashion, as well as providing some methods for easily
constructing common tables from regression output.

This package is still in beta.  I'm quite happy with it and I've been
using it (or some iteration of it) in my own work for quite a while.
But I'd appreciate feedback, feature requests, or pull requests (if you
want to help!).

# Installation

TexTables is not yet registered, so it can be installed by cloning it
from the repository.
```julia
Pkg.clone("https://github.com/jacobadenbaum/TexTables.jl.git")
```

# Basic Usage
The goal for this package is to make most tables extremely easy to
assemble on the fly.  In the next few sections, I'll demonstrate some of
the basic usage, primarily using several convenience functions that make
it easy to construct common tables.  However, these functions are a
small subset of what `TexTables` is designed for: it should be easy
to programatically make any type of hierarchical table and and print it
to LaTeX.  For more details on how to roll-your-own tables (or integrate
LaTeX tabular output into your own package) very easily using
`TexTables`, see the Advanced Usage section below.

## Making A Table of Summary Statistics
Let's download the `iris` dataset from `RDatasets`, and quickly
compute some summary statistics.

```julia
julia> using RDatasets, TexTables, DataStructures, DataFrames

julia> df = dataset("datasets", "iris");

julia> summarize(df)
            | Obs | Mean  | Std. Dev. |  Min  |  Max
------------------------------------------------------
SepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900
 SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400
PetalLength | 150 | 3.758 |     1.765 | 1.000 | 6.900
 PetalWidth | 150 | 1.199 |     0.762 | 0.100 | 2.500
    Species |     |       |           |       |
```
If we want more detail, we can pass the `detail=true` keyword argument:
```julia
julia> summarize(df,detail=true)
            | Obs | Mean  | Std. Dev. |  Min  |  p10  |  p25  |  p50  |  p75  |  p90  |  Max
----------------------------------------------------------------------------------------------
SepalLength | 150 | 5.843 |     0.828 | 4.300 | 4.800 | 5.100 | 5.800 | 6.400 | 6.900 | 7.900
 SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 2.500 | 2.800 | 3.000 | 3.300 | 3.610 | 4.400
PetalLength | 150 | 3.758 |     1.765 | 1.000 | 1.400 | 1.600 | 4.350 | 5.100 | 5.800 | 6.900
 PetalWidth | 150 | 1.199 |     0.762 | 0.100 | 0.200 | 0.300 | 1.300 | 1.800 | 2.200 | 2.500
    Species |     |       |           |       |       |       |       |       |       |

```
We can restrict to only some variables by passing a second positional
argument, which can be either a `Symbol` or an iterable collection of
symbols.

The summarize function is similar to the Stata command `summarize`: it
reports string variables all entries missing, and skips all missing
values when computing statistics.

To customize what statistics are calculated, you can pass `summarize`
a `stats::Tuple{Union{Symbol,String},Function}` (or just a single pair
will work too) keyword argument:
```julia
# Quantiles of nonmissing values (need to collect to pass to quantile)

julia> nomiss(x) = skipmissing(x) |> collect;

julia> new_stats = ("p25" => x-> quantile(nomiss(x), .25),
                    "p50" => x-> quantile(nomiss(x), .5),
                    "p75" => x-> quantile(nomiss(x), .75));

julia> summarize(df, stats=new_stats)
            |  p25  |  p50  |  p75
------------------------------------
SepalLength | 5.100 | 5.800 | 6.400
 SepalWidth | 2.800 | 3.000 | 3.300
PetalLength | 1.600 | 4.350 | 5.100
 PetalWidth | 0.300 | 1.300 | 1.800
    Species |       |       |
```

## Stacking Tables
It's easy to stack two tables that you created at different parts of
your code using calls to `hcat` or `vcat`:
```julia
julia> t11 = summarize(df, :SepalLength)
            | Obs | Mean  | Std. Dev. |  Min  |  Max
------------------------------------------------------
SepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900

julia> t21= summarize(df, :SepalWidth)
           | Obs | Mean  | Std. Dev. |  Min  |  Max
-----------------------------------------------------
SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400

julia> t12 = summarize(df, :SepalLength, stats=new_stats)
            |  p25  |  p50  |  p75
------------------------------------
SepalLength | 5.100 | 5.800 | 6.400

julia> t22 = summarize(df, :SepalWidth, stats=new_stats)
           |  p25  |  p50  |  p75
-----------------------------------
SepalWidth | 2.800 | 3.000 | 3.300

julia> tab = [t11   t12
              t21   t22]
            | Obs | Mean  | Std. Dev. |  Min  |  Max  |  p25  |  p50  |  p75
------------------------------------------------------------------------------
SepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900 | 5.100 | 5.800 | 6.400
 SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400 | 2.800 | 3.000 | 3.300
```

You can also group statistics together with a call to the function
`join_table`.  This constructs a new table with a column multi-index
that groups your data into two column blocks.
```julia
julia> join_table( "Regular Summarize"  =>vcat(t11, t21),
                    "My Detail"         =>vcat(t12, t22))
            |            Regular Summarize            |       My Detail
            | Obs | Mean  | Std. Dev. |  Min  |  Max  |  p25  |  p50  |  p75
------------------------------------------------------------------------------
SepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900 | 5.100 | 5.800 | 6.400
 SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400 | 2.800 | 3.000 | 3.300

```
There is an analagous function for creating multi-indexed row tables
`append_table`.  You can see it in action with a call to the function
`summarize_by`, which calculates summary statistics by grouping on a
variable.
```julia
julia> c1 = summarize_by(df, :Species, [:SepalLength, :SepalWidth])
           |             | Obs | Mean  | Std. Dev. |  Min  |  Max
-------------------------------------------------------------------
    setosa | SepalLength |  50 | 5.006 |     0.352 | 4.300 | 5.800
           |  SepalWidth |  50 | 3.428 |     0.379 | 2.300 | 4.400
-------------------------------------------------------------------
versicolor | SepalLength |  50 | 5.936 |     0.516 | 4.900 | 7.000
           |  SepalWidth |  50 | 2.770 |     0.314 | 2.000 | 3.400
-------------------------------------------------------------------
 virginica | SepalLength |  50 | 6.588 |     0.636 | 4.900 | 7.900
           |  SepalWidth |  50 | 2.974 |     0.322 | 2.200 | 3.800

julia> c2 = summarize_by(df, :Species, [:SepalLength, :SepalWidth],
                         stats=new_stats)
           |             |  p25  |  p50  |  p75
-------------------------------------------------
    setosa | SepalLength | 4.800 | 5.000 | 5.200
           |  SepalWidth | 3.200 | 3.400 | 3.675
-------------------------------------------------
versicolor | SepalLength | 5.600 | 5.900 | 6.300
           |  SepalWidth | 2.525 | 2.800 | 3.000
-------------------------------------------------
 virginica | SepalLength | 6.225 | 6.500 | 6.900
           |  SepalWidth | 2.800 | 3.000 | 3.175
```
Now, when we horizontally concatenate `c1` and `c2`, they will
automatically maintiain the block-ordering in the rows:
```julia
julia> final_table = join_table("Regular Summarize"=>c1, "My Detail"=>c2)
           |             |            Regular Summarize            |       My Detail
           |             | Obs | Mean  | Std. Dev. |  Min  |  Max  |  p25  |  p50  |  p75
-------------------------------------------------------------------------------------------
    setosa | SepalLength |  50 | 5.006 |     0.352 | 4.300 | 5.800 | 4.800 | 5.000 | 5.200
           |  SepalWidth |  50 | 3.428 |     0.379 | 2.300 | 4.400 | 3.200 | 3.400 | 3.675
-------------------------------------------------------------------------------------------
versicolor | SepalLength |  50 | 5.936 |     0.516 | 4.900 | 7.000 | 5.600 | 5.900 | 6.300
           |  SepalWidth |  50 | 2.770 |     0.314 | 2.000 | 3.400 | 2.525 | 2.800 | 3.000
-------------------------------------------------------------------------------------------
 virginica | SepalLength |  50 | 6.588 |     0.636 | 4.900 | 7.900 | 6.225 | 6.500 | 6.900
           |  SepalWidth |  50 | 2.974 |     0.322 | 2.200 | 3.800 | 2.800 | 3.000 | 3.175
```

## Exporting to Latex
Now that we've constructed our table, we want to be able to export it to
LaTeX so that we can show it to all of our friends and colleagues.
We can print the LaTeX table as a string with a call to `to_tex`:

```julia
julia> final_table |> to_tex |> print
\begin{tabular}{rr|ccccc|ccc}
\toprule
                            &             & \multicolumn{5}{c}{Regular Summarize}   & \multicolumn{3}{c}{My Detail} \\
                            &             & Obs & Mean  & Std. Dev. & Min   & Max   & p25     & p50     & p75     \\ \hline
    \multirow{2}{*}{setosa} & SepalLength &  50 & 5.006 &     0.352 & 4.300 & 5.800 &   4.800 &   5.000 &   5.200 \\
                            &  SepalWidth &  50 & 3.428 &     0.379 & 2.300 & 4.400 &   3.200 &   3.400 &   3.675 \\ \hline
\multirow{2}{*}{versicolor} & SepalLength &  50 & 5.936 &     0.516 & 4.900 & 7.000 &   5.600 &   5.900 &   6.300 \\
                            &  SepalWidth &  50 & 2.770 &     0.314 & 2.000 & 3.400 &   2.525 &   2.800 &   3.000 \\ \hline
 \multirow{2}{*}{virginica} & SepalLength &  50 & 6.588 &     0.636 & 4.900 & 7.900 &   6.225 &   6.500 &   6.900 \\
                            &  SepalWidth &  50 & 2.974 &     0.322 & 2.200 & 3.800 &   2.800 &   3.000 &   3.175 \\
\bottomrule
\end{tabular}
```
Or we could just print it directly to a file with the command
`write_tex("myfile.tex", final_table)`.  It's as simple as that.
TableTex will automatically handle printing it in a way that is well
aligned and can be read even from the raw tex file, and will align the
multi-columns and multi-indexes for you.

## Tabulate Function
`TexTables` also provides a convenience `tabulate` function:
```julia
julia> tabulate(df, :Species)
           | Freq. | Percent |  Cum.
---------------------------------------
    setosa |    50 |  33.333 |  33.333
versicolor |    50 |  33.333 |  66.667
 virginica |    50 |  33.333 | 100.000
---------------------------------------
     Total |   150 | 100.000 |
```
In the future, I may add support for two way tables (it's a very easy
extension).

## StatsModels Integrations

Let's say that we want to run a few regressions on some data that we
happened to come by:
```julia
using StatsModels, GLM
df = dataset("datasets", "attitude")
m1 = lm(@formula( Rating ~ 1 + Raises ), df)
m2 = lm(@formula( Rating ~ 1 + Raises + Learning), df)
m3 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges), df)
m4 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                             + Complaints), df)
m5 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                             + Complaints + Critical), df)
```
We can construct a single column for any one of these with the
`TableCol` constructor:
```julia
julia> t1 = TableCol("(1)", m1)
            |   (1)
-----------------------
(Intercept) |   19.978
            | (11.688)
     Raises |    0.691
            |  (0.179)
-----------------------
          N |       30
      $R^2$ |    0.348
```
We can combine them together with their own special names
```julia
julia> reg_table = hcat(TableCol("(1)", m1),
                        TableCol("(2)", m2),
                        TableCol("(3)", m3),
                        TableCol("(4)", m4),
                        TableCol("(5)", m5))
            |   (1)    |   (2)    |   (3)    |   (4)   |   (5)
------------------------------------------------------------------
(Intercept) |   19.978 |   15.809 |   14.167 |  11.834 |   11.011
            | (11.688) | (11.084) | (11.519) | (8.535) | (11.704)
     Raises |    0.691 |    0.379 |    0.352 |  -0.026 |   -0.033
            |  (0.179) |  (0.217) |  (0.224) | (0.184) |  (0.202)
   Learning |          |    0.432 |    0.394 |   0.246 |    0.249
            |          |  (0.193) |  (0.204) | (0.154) |  (0.160)
 Privileges |          |          |    0.105 |  -0.103 |   -0.104
            |          |          |  (0.168) | (0.132) |  (0.135)
 Complaints |          |          |          |   0.691 |    0.692
            |          |          |          | (0.146) |  (0.149)
   Critical |          |          |          |         |    0.015
            |          |          |          |         |  (0.147)
------------------------------------------------------------------
          N |       30 |       30 |       30 |      30 |       30
      $R^2$ |    0.348 |    0.451 |    0.459 |   0.715 |    0.715
```

Currently, `TexTables` works with several standard regression packages
in the `StatsModels` family to construct custom coefficient tables.
I've mostly implemented these as proof of concept, since I'm not sure
how best to proceed on extending it to more model types.

I think that I may spin these off into a "formulas" package at some
point in the future.

## Display Options

You can recover the string output using the functions `to_latex` and
`to_ascii`.  But, it is also possible to tweak the layout of the tables
by passing keyword arguments to the `print`, `show`, `to_tex`, or
`to_ascii` functions.  For instance, if you would like to display your
standard errors on the same row as the coefficients, you can do so with
the `se_pos` argument:
```julia
julia> print(to_ascii(hcat( TableCol("(1)", m1), TableCol("(2)", m2)),
                      se_pos=:inline))
            |       (1)       |       (2)
------------------------------------------------
(Intercept) | 19.978 (11.688) | 15.809 (11.084)
     Raises |   0.691 (0.179) |   0.379 (0.217)
   Learning |                 |   0.432 (0.193)
------------------------------------------------
          N |              30 |              30
      $R^2$ |           0.348 |           0.451
```

Currently, `TexTables` supports the following display options:
1.  `pad`::Int (default 1)
        The number of spaces to pad the separator characters on each side.
2.  `se_pos`::Symbol (default :below)
    1.  :below -- Prints standard errors in parentheses on a second line
        below the coefficients
    2.  :inline -- Prints standard errors in parentheses on the same
        line as the coefficients
    3.  :none -- Supresses standard errors.  (I don't know why you would
        want to do this... you probably shouldn't ever use it.)

In the very near future, I will be adding support for stars for
p-values, and it should be fairly easy to add custom table styles that
are particular to any given journal's requirements.

## Row and Column Blocks

As you can see, the summary statistics are kept in a separate row-block
while the columns are being merged together. We can do this either with
unnamed groups (like in the previous example), or with named groups that
will be visible in the table itself.

Suppose that our first 3 regressions needed to be visually grouped
together under a single heading, and the last two were separate.  We
could instead construct each group separately and then combine them
together with the `join_table` function:
```julia
group1 = hcat(  TableCol("(1)", m1),
                TableCol("(2)", m2),
                TableCol("(3)", m3))
group2 = hcat(  TableCol("(1)", m4),
                TableCol("(2)", m5))
grouped_table = join_table( "Group 1"=>group1,
                            "Group 2"=>group2)
```
This will display as:
```julia
julia> grouped_table = join_table( "Group 1"=>group1,
                                   "Group 2"=>group2)
            |            Group 1             |      Group 2
            |   (1)    |   (2)    |   (3)    |   (1)   |   (2)
------------------------------------------------------------------
(Intercept) |   19.978 |   15.809 |   14.167 |  11.834 |   11.011
            | (11.688) | (11.084) | (11.519) | (8.535) | (11.704)
     Raises |    0.691 |    0.379 |    0.352 |  -0.026 |   -0.033
            |  (0.179) |  (0.217) |  (0.224) | (0.184) |  (0.202)
   Learning |          |    0.432 |    0.394 |   0.246 |    0.249
            |          |  (0.193) |  (0.204) | (0.154) |  (0.160)
 Privileges |          |          |    0.105 |  -0.103 |   -0.104
            |          |          |  (0.168) | (0.132) |  (0.135)
 Complaints |          |          |          |   0.691 |    0.692
            |          |          |          | (0.146) |  (0.149)
   Critical |          |          |          |         |    0.015
            |          |          |          |         |  (0.147)
------------------------------------------------------------------
          N |       30 |       30 |       30 |      30 |       30
      $R^2$ |    0.348 |    0.451 |    0.459 |   0.715 |    0.715
```
And in latex, the group labels will be displayed with `\multicolumn`
commands:
```latex
\begin{tabular}{r|ccc|cc}
\toprule
            & \multicolumn{3}{c}{Group 1}    & \multicolumn{2}{c}{Group 2}\\
            & (1)      & (2)      & (3)      & (1)         & (2)          \\ \hline
(Intercept) &   19.978 &   15.809 &   14.167 &      11.834 &       11.011 \\
            & (11.688) & (11.084) & (11.519) &     (8.535) &     (11.704) \\
     Raises &    0.691 &    0.379 &    0.352 &      -0.026 &       -0.033 \\
            &  (0.179) &  (0.217) &  (0.224) &     (0.184) &      (0.202) \\
   Learning &          &    0.432 &    0.394 &       0.246 &        0.249 \\
            &          &  (0.193) &  (0.204) &     (0.154) &      (0.160) \\
 Privileges &          &          &    0.105 &      -0.103 &       -0.104 \\
            &          &          &  (0.168) &     (0.132) &      (0.135) \\
 Complaints &          &          &          &       0.691 &        0.692 \\
            &          &          &          &     (0.146) &      (0.149) \\
   Critical &          &          &          &             &        0.015 \\
            &          &          &          &             &      (0.147) \\ \hline
          N &       30 &       30 &       30 &          30 &           30 \\
      $R^2$ &    0.348 &    0.451 &    0.459 &       0.715 &        0.715 \\
\bottomrule
\end{tabular}
```
The vertical analogue of `join_table` is the function `append_table`.
Both will also accept the table objects as arguments instead of pairs if
you want to construct the row/column groups without adding a visible
multi-index.

# Advanced Usage

These sections are for advanced users who are interested in fine-tuning
their own custom tables or integrating `TexTables` into their packages.

## Building Tables from Scratch

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

### Constructing Columns From Vectors:

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
