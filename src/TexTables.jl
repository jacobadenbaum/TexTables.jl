module TexTables

# package code goes here

# Nice string formattting
using Formatting, DataStructures, DataFrames

# Required for StatsModels Integration
using StatsBase
using GLM: LinearModel
using StatsModels: DataFrameRegressionModel
using Parameters

export FormattedNumber, FNum, FNumSE, @fmt, TableCol
export TableCol, Table
export IndexedTable, append_table, join_table, promote_rule
export to_tex, to_ascii, write_tex

# Import from base to extend
import Base.getindex, Base.setindex!, Base.push!
import Base: isless, ==
import Base: getindex, size, hcat, vcat, convert, promote_rule
import Base: show, size, print

export summarize, tabulate

# Need this abstract type
abstract type TexTable end

include("FormattedNumbers.jl")
include("TableCol.jl")
include("CompositeTable.jl")
include("Printing.jl")
include("StatsModelsInterface.jl")
include("QuickTools.jl")
end # module
