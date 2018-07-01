# Easy Examples

Here are just a couple examples of tables that TexTables makes extremely easy to
produce and export.  These are mostly proof of concept: TexTables provides a
backend that makes the code to write these convenience methods extremely [compact] (https://github.com/jacobadenbaum/TexTables.jl/blob/master/src/QuickTools.jl).

## Regression Tables
```@meta
DocTestSetup = quote
    # Get the warning out of the way before we start
    using TexTables, StatsModels, GLM, RDatasets
    df = dataset("datasets", "iris")
end
```
```jldoctest ex1
using TexTables, StatsModels, GLM, RDatasets
df = dataset("datasets", "attitude");
m1 = lm(@formula( Rating ~ 1 + Raises ), df);
m2 = lm(@formula( Rating ~ 1 + Raises + Learning), df);
m3 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges), df);
m4 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                             + Complaints), df);
m5 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                                    + Complaints + Critical), df);
table = regtable(m1, m2, m3, m4, m5)

# output

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

## Grouped Regression Tables
We can add a add a hierarchical structure by passing the model objects as pairs
of Strings/Symbols and model objects/tuples of model objects:

```jldoctest ex1
grouped_table = regtable(   "Group 1"=>(m1,m2,m3),
                            "Group 2"=>(m4, m5))

# output
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

## Exporting to Latex

All of these commands return subtypes of the abstract `TexTable` type.  Any
`TexTable` can be printed as either an ascii table (as shown above) with the
method `to_ascii` or as a latex table with the method `to_tex`:
```jldoctest ex1
to_tex(grouped_table) |> print

# output

\begin{tabular}{r|ccc|cc}
\toprule
            & \multicolumn{3}{c}{Group 1}    & \multicolumn{2}{c}{Group 2} \\
            & (1)      & (2)      & (3)      & (4)          & (5)          \\ \hline
(Intercept) &  19.978* &   15.809 &   14.167 &       11.834 &       11.011 \\
            & (11.688) & (11.084) & (11.519) &      (8.535) &     (11.704) \\
     Raises & 0.691*** &   0.379* &    0.352 &       -0.026 &       -0.033 \\
            &  (0.179) &  (0.217) &  (0.224) &      (0.184) &      (0.202) \\
   Learning &          &  0.432** &   0.394* &        0.246 &        0.249 \\
            &          &  (0.193) &  (0.204) &      (0.154) &      (0.160) \\
 Privileges &          &          &    0.105 &       -0.103 &       -0.104 \\
            &          &          &  (0.168) &      (0.132) &      (0.135) \\
 Complaints &          &          &          &     0.691*** &     0.692*** \\
            &          &          &          &      (0.146) &      (0.149) \\
   Critical &          &          &          &              &        0.015 \\
            &          &          &          &              &      (0.147) \\ \hline
          N &       30 &       30 &       30 &           30 &           30 \\
      $R^2$ &    0.348 &    0.451 &    0.459 &        0.715 &        0.715 \\
\bottomrule
\end{tabular}
```
It's as simple as that.  As you can see, higher level groupings will be
separated with vertical bars, and their headings will be printed as
`\multicolumn` environments.  In tables with row-groupings, TexTables will
automatically use `\multirow` environments.  TableTex will automatically handle
printing it in a way that is well aligned and can be read even from the raw tex
file, and will align the multi-columns and multi-indexes for you.

You can write the table to a tex file yourself, or you can use the convenience
wrapper `write_tex(fpath::String, t::TexTable)`.

## Summary Tables

Making summary tables is similarly easy:

```jldoctest ex1
df = dataset("datasets", "iris");
summarize(df)

# output
            | Obs | Mean  | Std. Dev. |  Min  |  Max
------------------------------------------------------
SepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900
 SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400
PetalLength | 150 | 3.758 |     1.765 | 1.000 | 6.900
 PetalWidth | 150 | 1.199 |     0.762 | 0.100 | 2.500
    Species |     |       |           |       |
```

To choose only a subset of variables, and get a more detailed summary table:
```jldoctest ex1
summarize(df, [:SepalLength, :SepalWidth], detail=true)

# output
            | Obs | Mean  | Std. Dev. |  Min  |  p10  |  p25  |  p50  |  p75  |  p90  |  Max
----------------------------------------------------------------------------------------------
SepalLength | 150 | 5.843 |     0.828 | 4.300 | 4.800 | 5.100 | 5.800 | 6.400 | 6.900 | 7.900
 SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 2.500 | 2.800 | 3.000 | 3.300 | 3.610 | 4.400
```

To group by another variable in the DataFrame, use the `summarize_by` function:

```jldoctest ex1
c1 = summarize_by(df, :Species, [:SepalLength, :SepalWidth])

# output

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
```
