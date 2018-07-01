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

## Installation

TexTables is not yet registered, so it can be installed by cloning it
from the repository.
```julia
Pkg.clone("https://github.com/jacobadenbaum/TexTables.jl.git")
```
