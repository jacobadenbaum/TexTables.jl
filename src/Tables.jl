module Tables

# package code goes here
# Nice string formattting
using Formatting, StatsBase


export FormattedNumber, FNum, FNumSE, @fmt, TableCol
export TableCol, Table, tex, write_tex
export CompositeTable, row_keys, col_keys, IndexedTable

# Import from base to extend
import Base.getindex, Base.setindex!, Base.push!

abstract type TexTable end

include("FormattedNumbers.jl")
include("TableCol.jl")
include("CompositeTable.jl")
include("Printing.jl")

# include("TableFull.jl")
# include("StatsModelsInterface.jl")

end # module
