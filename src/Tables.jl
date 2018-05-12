module Tables

# package code goes here
# Nice string formattting
using Formatting, StatsBase


export FormattedNumber, FNum, FNumSE, @fmt, TableCol
export TableCol, Table, tex, write_tex
export CompositeTable, row_keys, col_keys

# Import from base to extend
import Base.getindex, Base.setindex!, Base.push!

include("FormattedNumbers.jl")
include("TableCol.jl")
include("TableFull.jl")
include("StatsModelsInterface.jl")
include("CompositeTable.jl")

end # module
