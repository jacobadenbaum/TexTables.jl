#=
This code provides the framework to stich together two separate tables
(either concatenating them horizontally or vertically).  
=#

mutable struct CompositeTable <: TexTable
    Tables::Matrix{TexTable}
    RowHeader::Vector{Printable}
    ColHeader::Vector{Printable}

    CompositeTable(t,r,c) = begin
        @assert(all(size(t) .== (length(r), length(c))),
                "Rows and Columns are the wrong lengths")
        return new(t,r,c)
    end
end



function row_keys(t::CompositeTable)
    out = []
    for (i, key) in enumerate(t.RowHeader)
        for j = 1:size(t.Tables,2)
            out = union(out, tuple.(key, row_keys(t.Tables[i,j])...))
        end
    end
    return out
end

function col_keys(t::CompositeTable)
    out = []
    n, m = size(t.Tables)
    for j=1:m, i=1:n
        key = t.ColHeader[j]
        out = union(out, tuple.(key, col_keys(t.Tables[i,j])...))
    end
    return out
end
