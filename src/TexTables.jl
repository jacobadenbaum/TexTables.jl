module TexTables

# package code goes here

# Nice string formattting
using Formatting, DataStructures

# Required for StatsModels Integration
using StatsBase
using GLM: LinearModel
using StatsModels: DataFrameRegressionModel
using Parameters

export FormattedNumber, FNum, FNumSE, @fmt, TableCol
export TableCol, Table, tex, write_tex
export IndexedTable, append_table, join_table, promote_rule

# Import from base to extend
import Base.getindex, Base.setindex!, Base.push!
import Base: isless, ==
import Base: getindex, size, hcat, vcat, convert, promote_rule
import Base: show, size

# Need this abstract type
abstract type TexTable end

include("FormattedNumbers.jl")
include("TableCol.jl")
include("CompositeTable.jl")
include("Printing.jl")
include("StatsModelsInterface.jl")

end # module
