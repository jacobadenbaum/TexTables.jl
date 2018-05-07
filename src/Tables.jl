module Tables

# package code goes here
# Nice string formattting
using Formatting


export FormattedNumber, FNum, FNumSE, @fmt, TableCol
export TableCol, Table, tex, write_tex

# Import from base to extend
import Base.getindex, Base.setindex!, Base.push!

include("FormattedNumbers.jl")
include("TableCol.jl")
include("TableFull.jl")

end # module
