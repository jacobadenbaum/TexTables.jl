# Introduction
The TexTable package provides an easy way for Julia users to quickly build
well-formated and publication-ready ASCII and LaTeX tables from a variety of
different data structures.  It allows the user to easily build complex tables
from small, modular components in an object oriented fashion, as well as
providing some methods for easily constructing common tables from regression
output.

TexTables.jl is designed for building all sorts of statistical tables in a very
modular fashion and for quickly displaying them in the REPL or exporting them to
LaTeX.  It’s quite extensible, and probably the most important use cases will be
for people who want to make their own custom tables, but it has implemented
support for some basic regression tables, cross-tabulations, and summary
statistics as proof-of-concept.

## Features
Currently TexTables will allow you to:
1.  Build multi-indexed tables programatically with a simple to use interface
    that allows for row and column groupings.
2.  Print them in the REPL as ASCII tables, or export them to LaTeX for easy
    inclusion

It also provides constructors and methods to
3.  Quickly construct regression tables from estimated models that adhere to the
    `LinearModel` API.
    1.  Add customized model metadata (such as the type of estimator used, etc...)
    2.  Group regression columns into subgroups using multicolumn headings
    3.  Add significance stars to coefficient estimates.
    4.  Use robust standard errors from CovarianceMatrices.jl or other packages.
4.  Construct several standard tables that may be useful in exploratory data
    analysis
    1.  Summary tables
    2.  Grouped summary tables.
    3.  One-way frequency tbales.

## Installation

TexTables is not yet registered, so it can be installed with the command
```julia
Pkg.add("TexTables")
```
