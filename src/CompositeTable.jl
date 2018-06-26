#=
This code provides the framework to stich together two separate tables
(either concatenating them horizontally or vertically).
=#

import Base: join, getindex, size

mutable struct CompositeTable <: TexTable
    Tables::Array{TexTable}
    ColHeader::Vector{AbstractString}
    RowHeader::Vector{AbstractString}
    CompositeTable(tables::Union{Array{T},T},
                   ColHeader=String[],
                   RowHeader=String[]) where T <: TexTable = begin

        # Need to do some argument checking
        t    = Table.(hcat(tables))
        n, m = size(t)
        q, r = length(RowHeader), length(ColHeader)

        # If the row headers are not empty, check that there's one for
        # every row of sub-tables.  Otherwise, use vector of empty
        # strings.
        if q > 0
            if q != n
                throw(ArgumentError("Invalid number of Row Headers"))
            end
            rows = RowHeader
        else
            rows = ["" for i=1:n]
        end

        # If the col headers are not empty, check that there's one for
        # every column of sub-tables.  Otherwise, use a vector of empty
        # strings.
        if r > 0
            if r != m
                throw(ArgumentError("Invalid number of Column Headers"))
            end
            cols = ColHeader
        else
            cols = ["" for i=1:m]
        end

        # Check that all the tables have the same depth
        if !(allequal(depth.(t)))
            msg = "All sub-tables must have the same depth"
            throw(ArgumentError(msg))
        end

        # Construct the composite table.
        return new(t, cols, rows)
    end
end

CTable = CompositeTable
function CompositeTable(t::Table,
                        ColHeader=String[],
                        RowHeader=String[])
    return CTable([t], ColHeader, RowHeader)
end

CompositeTable(t::CTable) = t
Table(t::CTable) = t


size(t::CTable, args...) = size(t.Tables, args...)

########################################################################
#################### Join Methods ######################################
########################################################################

allequal(x) = all(y->y==x[1], x)

function join(t1::Table, t2::Table)
    t1 = deepcopy(t1)
    for col in t2.Columns
        push!(t1, col)
    end
    return t1
end

function join(t1::CTable, t2::CTable)
    if (col_depth(t1) > 1) | (col_depth(t2) > 1)
        msg = "Cannot join tables more than 1 column layer deep. "
        msg *= "Try breaking it up into smaller pieces"
        throw(ArgumentError(msg))
    end

    if (row_depth(t1) > 2) | (row_depth(t2) > 2)
        msg = "Cannot join tables more than 2 row layers deep. "
        msg *= "Try breaking it up into smaller pieces"
        throw(ArgumentError(msg))
    end

    if t1.RowHeader != t2.RowHeader
        msg  = "Cannot join Composite Tables that don't have "
        msg *= "the same row-shape. "
        msg *= "Try breaking it up into smaller pieces"
        throw(ArgumentError(msg))
    end

    if t1.ColHeader != t2.ColHeader
        ColHeader = [""]
        warn("Dropping Inconsistent ColHeader names.")
    else
        ColHeader = t1.ColHeader
    end

    # Do the join row-block by row-block
    joined = [join(t1[i,1], t2[i,1]) for i=1:size(t1, 1)]

    return CompositeTable(joined, t1.ColHeader, t2.RowHeader)
end

function join(t1::CTable,
              tables::Vararg{CTable, 2})
    return join(join(t1, tables[1]), tables[2])
end

function join(t1::CTable,
              tables::Vararg{CTable, N}) where N
    return join(join(t1, tables[1]), tables[2:end])
end

########################################################################
#################### Traversing Methods ################################
########################################################################

function depth(t::CompositeTable)::Int
    d = maximum(depth.(t.Tables))
    return d + 1
end

function col_depth(t::CompositeTable)::Int

    # Recurse through the sub-tables
    d = maximum(col_depth.(t.Tables))

    # Add in the depth contribution of the current table
    if length(t.ColHeader) == 1
        return 0 + d
    else
        return 1 + d
    end
end

function row_depth(t::CompositeTable)::Int
    # Recurse through the sub-tables
    d = maximum(row_depth.(t.Tables))

    # Add in the depth contribution of the current table
    if length(t.RowHeader) == 1
        return 0 + d
    else
        return 1 + d
    end
end

depth(t::Table) = 1
col_depth(t::Table) = 1
row_depth(t::Table) = 1

getindex(t::CTable, idx1, idx2) = t.Tables[idx1, idx2]

"""
```
row_index(t::TexTable)
```
This function returns a vector of NTuples corresponding to the fully
specified row multi-index of the composite table.  Each Tuple will have
string entries and have length `row_depth(t)`
"""
function row_index(t::CompositeTable)
    headers = []
    for (i, row_label) in enumerate(t.RowHeader)
        for (j, col_label) in enumerate(t.ColHeader)
            # Extract the headers for the subtable recursively
            sub_headers = row_index(t[i,j])

            # Insert them into the list of headers for this section in
            # the order we encounter them.
            for sub_header in sub_headers

                # Represent empty with integer (not type stable at all,
                # but it doesn't matter since this code never needs to
                # be performant)
                rlab = i

                # Make our new header
                new_header = tuple(rlab, sub_header...)

                # Push it to the list of row headers if we haven't
                # already encountered it encountered it
                if !(new_header in headers)
                    push!(headers, new_header)
                end
            end
        end
    end
    return headers
end

row_index(t::Table) = tuple.(1:length(t.RowHeader))

"""
```
col_index(t::TexTable)
```
This function returns a vector of NTuples corresponding to the fully
specified column multi-index of the composite table.  Each Tuple will
have string entries and have length `col_depth(t)`
"""
function col_index(t::CompositeTable)
    headers = []
    for (j, col_label) in enumerate(t.ColHeader)
        for (i, row_label) in enumerate(t.RowHeader)
            # Extract the headers for the subtable recursively
            sub_headers = col_index(t[i,j])

            # Insert them into the list of headers for this section in
            # the order we encounter them.
            for sub_header in sub_headers

                # Represent empty with integer (not type stable at all,
                # but it doesn't matter since this code never needs to
                # be performant)
                clab = j

                # Make our new header
                new_header = tuple(clab, sub_header...)

                # Push it to the list of col headers if we haven't
                # already encountered it encountered it
                if !(new_header in headers)
                    push!(headers, new_header)
                end
            end
        end
    end
    return headers
end

col_index(t::Table) = tuple.(1:length(t.ColHeader))

get_col(t::CTable, col::Tuple)  = begin
    sub_table = map(t[:, col[1]]) do sub
        trim(get_col(sub, col[2:end]))
    end

    return sub_table
end

function trim(x::Array)
    if length(x) == 1
        return trim(x[1])
    else
        return x
    end
end

trim(x) = x



########################################################################
#################### Printing Methods ##################################
########################################################################

function get_length(t::CTable, col::Tuple)
    sub = get_col(t, col)
    l   = maximum(get_length.(sub))
end

function rowheader_length(t::CTable)
    rstr = row_index(t)
    N    = depth(t)

    l    = 0
    for i=1:N-1
        l += map(rstr) do r


        end

    end


end

function head(t::CTable)

    N = depth(t)

    ridx = row_index(t)



end
