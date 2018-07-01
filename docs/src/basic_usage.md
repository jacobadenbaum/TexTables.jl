# Basic Usage
The goal for this package is to make most tables extremely easy to
assemble on the fly.  In the next few sections, I'll demonstrate some of
the basic usage, primarily using several convenience functions that make
it easy to construct common tables.  However, these functions are a
small subset of what `TexTables` is designed for: it should be easy
to programatically make any type of hierarchical table and and print it
to LaTeX.  For more details on how to easily roll-your-own tables (or
integrate LaTeX tabular output into your own package) using `TexTables`,
see the Advanced Usage section below.

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
(Intercept) |  19.978*
            | (11.688)
     Raises | 0.691***
            |  (0.179)
-----------------------
          N |       30
      $R^2$ |    0.348
```
But in general, it is easier to just use the `regtable` function when
combining several different models:
```julia
julia> reg_table = regtable(m1, m2, m3, m4, m5)
            |   (1)    |   (2)    |   (3)    |   (4)    |   (5)
-------------------------------------------------------------------
(Intercept) |  19.978* |   15.809 |   14.167 |   11.834 |   11.011
            | (11.688) | (11.084) | (11.519) |  (8.535) | (11.704)
     Raises | 0.691*** |   0.379* |    0.352 |   -0.026 |   -0.033
            |  (0.179) |  (0.217) |  (0.224) |  (0.184) |  (0.202)
   Learning |          |  0.432** |   0.394* |    0.246 |    0.249
            |          |  (0.193) |  (0.204) |  (0.154) |  (0.160)
 Privileges |          |          |    0.105 |   -0.103 |   -0.104
            |          |          |  (0.168) |  (0.132) |  (0.135)
 Complaints |          |          |          | 0.691*** | 0.692***
            |          |          |          |  (0.146) |  (0.149)
   Critical |          |          |          |          |    0.015
            |          |          |          |          |  (0.147)
-------------------------------------------------------------------
          N |       30 |       30 |       30 |       30 |       30
      $R^2$ |    0.348 |    0.451 |    0.459 |    0.715 |    0.715
```

Currently, `TexTables` works with several standard regression packages
in the `StatsModels` family to construct custom coefficient tables.
I've mostly implemented these as proof of concept, since I'm not sure
how best to proceed on extending it to more model types.  By default,
`TexTables` will display significance stars using p-value thresholds of
0.1 for 1 star, 0.05 for 2 stars, and 0.01 for 3 stars (as is standard).

I think that I may spin these off into a "formulas" package at some
point in the future.

If you are interested in integrating `TexTables` into your regression
package, please see the topic below under "Advanced Usage."

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
group1 = regtable(m1, m2, m3)
group2 = regtable(m4, m5)
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
If instead, we wanted to maintain a consistent numbering from (1)-(5),
we could do it using the `regtable` function:
```julia
julia> regtable("Group 1"=>(m1, m2, m3), "Group 2"=>(m4, m5))
            |            Group 1             |       Group 2
            |   (1)    |   (2)    |   (3)    |   (4)    |   (5)
-------------------------------------------------------------------
(Intercept) |  19.978* |   15.809 |   14.167 |   11.834 |   11.011
            | (11.688) | (11.084) | (11.519) |  (8.535) | (11.704)
     Raises | 0.691*** |   0.379* |    0.352 |   -0.026 |   -0.033
            |  (0.179) |  (0.217) |  (0.224) |  (0.184) |  (0.202)
   Learning |          |  0.432** |   0.394* |    0.246 |    0.249
            |          |  (0.193) |  (0.204) |  (0.154) |  (0.160)
 Privileges |          |          |    0.105 |   -0.103 |   -0.104
            |          |          |  (0.168) |  (0.132) |  (0.135)
 Complaints |          |          |          | 0.691*** | 0.692***
            |          |          |          |  (0.146) |  (0.149)
   Critical |          |          |          |          |    0.015
            |          |          |          |          |  (0.147)
-------------------------------------------------------------------
          N |       30 |       30 |       30 |       30 |       30
      $R^2$ |    0.348 |    0.451 |    0.459 |    0.715 |    0.715
```
And in latex, the group labels will be displayed with `\multicolumn`
commands:
```latex
\begin{tabular}{r|ccc|cc}
\toprule
            & \multicolumn{3}{c}{Group 1}    & \multicolumn{2}{c}{Group 2}\\
            & (1)      & (2)      & (3)      & (4)         & (5)          \\ \hline
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
            |       (1)        |       (2)
-------------------------------------------------
(Intercept) | 19.978* (11.688) | 15.809 (11.084)
     Raises | 0.691*** (0.179) |  0.379* (0.217)
   Learning |                  | 0.432** (0.193)
-------------------------------------------------
          N |               30 |              30
      $R^2$ |            0.348 |           0.451
```

Similarly, if you want to print a table without showing the significance
stars, then simply pass the keyword argument `star=false`:

```julia
julia> print(to_ascii(hcat( TableCol("(1)", m1), TableCol("(2)", m2)),
                      star=false))
            |   (1)    |   (2)
----------------------------------
(Intercept) |   19.978 |   15.809
            | (11.688) | (11.084)
     Raises |    0.691 |    0.379
            |  (0.179) |  (0.217)
   Learning |          |    0.432
            |          |  (0.193)
----------------------------------
          N |       30 |       30
      $R^2$ |    0.348 |    0.451

```

Currently, `TexTables` supports the following display options:
1.  `pad::Int` (default `1`)
        The number of spaces to pad the separator characters on each side.
2.  `se_pos::Symbol` (default `:below`)
    1.  :below -- Prints standard errors in parentheses on a second line
        below the coefficients
    2.  :inline -- Prints standard errors in parentheses on the same
        line as the coefficients
    3.  :none -- Supresses standard errors.  (I don't know why you would
        want to do this... you probably shouldn't ever use it.)
3.  `star::Bool` (default `true`)
        If true, then prints any table entries that have been decorated
        with significance stars with the appropriate number of stars.

## Changing the Default Formatting

`TexTables` stores all of the table entries using special formatting
aware container types types that are subtypes of the abstract type
`FormattedNumber`.  By default, `TexTables` displays floating points
with three decimal precision (and auto-converts to scientific notation
for values less than 1e-3 and greater than 1e5).  Formatting is done
using Python-like formatting strings (Implemented by the excellent
[Formatting.jl](https://github.com/JuliaIO/Formatting.jl) package) If you
would like to change the default formatting values, you can do so using
the macro `@fmt`:

```julia
@fmt Real = "{:.3f}"        # Sets the default for reals to .3 fixed precision
@fmt Real = "{:.2f}"        # Sets the default for reals to .2 fixed precision
@fmt Real = "{:.2e}"        # Sets the default for reals to .2 scientific
@fmt Int  = "{:,n}"         # Sets the default for integers to use commas
@fmt Bool = "{:}"           # No extra formatting for Bools
@fmt AbstractString= "{:}"  # No extra formatting for Strings
```
Note that this controls the _defaults_ used when constructing a
`FormattedNumber`.  If you want to change the formatting in a table that
has already been constructed, you need to manually change the `format`
field of each entry in the table:
```julia
julia> x = FormattedNumber(5.0)
5.000

julia> x.format
"{:.3f"}

julia> x.format = "{:.3e}";
julia> x
5.000e+00
```
