# TexTables.jl

The TexTable package provides an easy way for Julia users to quickly
build well-formated and publication-ready ASCII and LaTeX tables from a
variety of different data structures.  It allows the user to easily
concatenate tables along either dimension (horizontally or vertically)
while preserving any important block structure in the tables.

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
    stats = OrderedDict("N"     => length(x),
                        "Mean"  => mean(x),
                        "Std"   => std(x),
                        "Min"   => minimum(x),
                        "Max"   => maximum(x))
    push!(cols, Table(header, stats))
end
```
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
   N | 30     | 30         | 30         | 30       | 30     | 30       | 30
Mean | 64.633 | 66.600     | 53.133     | 56.367   | 64.633 | 74.767   | 42.933
 Std | 12.173 | 13.315     | 12.235     | 11.737   | 10.397 | 9.895    | 10.289
 Min | 40     | 37         | 30         | 34       | 43     | 49       | 25
 Max | 85     | 90         | 83         | 75       | 88     | 92       | 72
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
   N & 30     & 30         & 30         & 30       & 30     & 30       & 30      \\
Mean & 64.633 & 66.600     & 53.133     & 56.367   & 64.633 & 74.767   & 42.933  \\
 Std & 12.173 & 13.315     & 12.235     & 11.737   & 10.397 & 9.895    & 10.289  \\
 Min & 40     & 37         & 30         & 34       & 43     & 49       & 25      \\
 Max & 85     & 90         & 83         & 75       & 88     & 92       & 72      \\
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
julia> t1 = Table("(1)", m1)
            |   (1)
-----------------------
(Intercept) | 19.978
            | (11.688)
     Raises | 0.691
            | (0.179)
-----------------------
          N | 30
      $R^2$ | 0.348
```
We can combine them together with their own special names
```julia
julia> reg_table = hcat(Table("(1)", m1),
                        Table("(2)", m2),
                        Table("(3)", m3),
                        Table("(4)", m4),
                        Table("(5)", m5))
           |   (1)    |   (2)    |   (3)    |   (4)   |   (5)
------------------------------------------------------------------
(Intercept) | 19.978   | 15.809   | 14.167   | 11.834  | 11.011
            | (11.688) | (11.084) | (11.519) | (8.535) | (11.704)
     Raises | 0.691    | 0.379    | 0.352    | -0.026  | -0.033
            | (0.179)  | (0.217)  | (0.224)  | (0.184) | (0.202)
   Learning |          | 0.432    | 0.394    | 0.246   | 0.249
            |          | (0.193)  | (0.204)  | (0.154) | (0.160)
 Privileges |          |          | 0.105    | -0.103  | -0.104
            |          |          | (0.168)  | (0.132) | (0.135)
 Complaints |          |          |          | 0.691   | 0.692
            |          |          |          | (0.146) | (0.149)
   Critical |          |          |          |         | 0.015
            |          |          |          |         | (0.147)
------------------------------------------------------------------
          N | 30       | 30       | 30       | 30      | 30
      $R^2$ | 0.348    | 0.451    | 0.459    | 0.715   | 0.715
```
As you can see, the summary statistics are kept in a separate row-block
while the columns are being merged together.  In the next section, we
will see how to construct custom tables that have this property.

Currently, `TexTables` works with several standard regression packages
in the `StatsModels` family to construct custom coefficient tables.
I've mostly implemented these as proof of concept, since I'm not sure
how best to proceed on extending it to more model types.

I think that I may spin these off into a "formulas" package at some
point in the future.

# Advanced Usage

These sections are for advanced users who are interested in fine-tuning
their own custom tables or integrating `TexTables` into their packages.

## Row and Column Blocks

## Multiindexing

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
