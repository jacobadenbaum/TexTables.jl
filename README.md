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
assemble on the fly.  Let's try a simple example (inspired by the
documentation in the `stargazer` package for `R`) using the "attitudes"
data from `RDatasets` to make a table with summary statistics.

## Making A New Table
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
The base unit of `TexTables` is the `TableCol` type -- it represents a
header and an OrderedDict of keys and values using special indices that
allow the user to easily combine tables together.

Each entry of `cols` is it's own table, which we can view in the REPL:
```julia
julia> cols[1]
     | Rating
--------------
   N | 30
Mean | 64.633
 Std | 12.173
 Min | 40
 Max | 85
```
However, we can easily join two or more of them together horizontally or
vertically with the `hcat` and `vcat` functions.  The output will
display in the REPL as a formatted ASCII table
```julia
julia> tab = hcat(cols...)
     | Rating | Complaints | Privileges | Learning | Raises | Critical | Advance
---------------------------------------------------------------------------------
   N |     30 |         30 |         30 |       30 |     30 |       30 |      30
Mean | 64.633 |     66.600 |     53.133 |   56.367 | 64.633 |   74.767 |  42.933
 Std | 12.173 |     13.315 |     12.235 |   11.737 | 10.397 |    9.895 |  10.289
 Min |     40 |         37 |         30 |       34 |     43 |       49 |      25
 Max |     85 |         90 |         83 |       75 |     88 |       92 |      72

```

## Exporting the Table to LaTeX

Or, we can save the table as a formatted LaTeX table with the command
```julia
write_tex("mytable.tex", tab)
```
When we open this table, we will get a human-readable LaTeX table:

```latex
\begin{tabular}{r|ccccccc}
\toprule
     & Rating & Complaints & Privileges & Learning & Raises & Critical & Advance \\ \hline
   N &     30 &         30 &         30 &       30 &     30 &       30 &      30 \\
Mean & 64.633 &     66.600 &     53.133 &   56.367 & 64.633 &   74.767 &  42.933 \\
 Std & 12.173 &     13.315 &     12.235 &   11.737 & 10.397 &    9.895 &  10.289 \\
 Min &     40 &         37 &         30 &       34 &     43 &       49 &      25 \\
 Max &     85 &         90 &         83 &       75 &     88 &       92 &      72 \\
\bottomrule
\end{tabular}
```
## StatsModels Integrations

Let's say that we want to run a few regressions on this data:
```julia
using StatsModels, GLM
m1 = lm(@formula( Rating ~ 1 + Raises ), df)
m2 = lm(@formula( Rating ~ 1 + Raises + Learning), df)
m3 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges), df)
m4 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                             + Complaints), df)
m5 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                             + Complaints + Critical), df)
```
We can view any one of these as it's own table with the same kind of
`Table` constructor as before:
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

## A word of caution about merging tables

Be careful when you are stacking tables: `TexTables` does not stack them
positionally.  It merges them on the the appropriate column or row keys.
So, if we go back to our earlier example of summary statistics: if we
were to vertically stack two of these tables, we would get something
weird looking:
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
Not quite what we wanted...  Whenever you concatenate two tables, they
need to have the same structure in the dimension that they are not being
joined upon.
