#=
This code provides the framework to stich together two separate tables
(either concatenating them horizontally or vertically).
=#

mutable struct IndexedTable{N, M} <: TexTable
    columns::Vector
    row_index::Index{N}
    col_index::Index{M}
end

IndexedTable(t::TableCol) = begin
    columns     = [t]
    row_index   = keys(t.data) |> collect |> sort
    col_index   = [t.header]
    return IndexedTable(columns, row_index, col_index)
end

convert(::Type{IndexedTable}, t::TexTable) = IndexedTable(t)
convert(::Type{IndexedTable}, t::IndexedTable) = t

################################################################################
#################### Merging and Concatenating #################################
################################################################################

function vcat(t1::IndexedTable, t2::IndexedTable)

    # Promote to the same dimensions
    t1, t2 = deepcopy.(promote(t1, t2))

    # Row Indices stay the same except within the highest group, where they need
    # to be shifted up in order to keep the index unique
    shift       =   maximum(get_idx(t1.row_index, 1)) -
                    minimum(get_idx(t2.row_index, 1)) + 1
    new_index   = map(t2.row_index) do idx
        i1 = idx.idx[1] + shift
        new_idx = tuple(i1, idx.idx[2:end]...)
        return update_index(idx, new_idx)
    end

    new_columns = deepcopy(t2.columns)
    for col in new_columns
        for (idx, new_idx) in zip(t2.row_index, new_index)
            if haskey(col.data, idx)
                col[new_idx] = pop!(col.data, idx)
            end
        end
    end

    row_index = vcat(t1.row_index, new_index)

    # Columns
    col_index = deepcopy(t1.col_index)
    columns   = deepcopy(t1.columns)
    for (i, idx) in enumerate(t2.col_index)

        # Figure out where to insert the column
        new_idx, s = insert_index!(col_index, idx)

        # It might be a new column
        if s > length(columns)
            push!(columns, new_columns[i])
        # If not, we need to move all the data over
        else
            for (key, value) in new_columns[i].data
                columns[s].data[key] = value
            end
        end
    end


    return IndexedTable(columns, row_index, col_index)

end

function hcat(t1::IndexedTable, t2::IndexedTable)

    # Promote to the same dimensions
    t1, t2 = deepcopy.(promote(t1, t2))

    # Column Indices stay the same except within the highest group,
    # where they need to be shifted up in order to keep the index unique
    shift       =   maximum(get_idx(t1.col_index, 1)) -
                    minimum(get_idx(t2.col_index, 1)) + 1
    new_index   = map(t2.col_index) do idx
        i1 = idx.idx[1] + shift
        return update_index(idx, tuple(i1, idx.idx[2:end]...))
    end
    col_index   = vcat(t1.col_index, new_index)


    # Row indices are merged in (inserted) one at a time, maintaining
    # strict insertion order in all index levels but the lowest one
    new_columns = deepcopy(t2.columns)
    row_index   = t1.row_index
    for idx in t2.row_index

        # Insert the index and recover the new_index and the required
        # insertion point
        new_idx, s = insert_index!(row_index, idx)

        # Rename the old indexes to the new ones
        for col in new_columns
            if haskey(col.data, idx)
                val          = pop!(col.data, idx)
                col[new_idx] = val
            end
        end
    end

    # Remap the internal column headers to keep them consistent
    old_new     = Dict(Pair.(t2.col_index, new_index))
    for col in new_columns
        col.header = old_new[col.header]
    end

    # Now, we're ready to append the columns together.
    columns     = vcat(t1.columns, new_columns)
    return IndexedTable(columns, row_index, col_index)
end

hcat(tables::Vararg{TexTable}) = reduce(hcat, tables)
vcat(tables::Vararg{TexTable}) = reduce(vcat, tables)

function hvcat(rows::Tuple{Vararg{Int}}, as::Vararg{TexTable})
    nbr = length(rows)  # number of block rows
    rs = Array{Any,1}(undef, nbr)
    a = 1
    for i = 1:nbr
        rs[i] = hcat(as[a:a-1+rows[i]]...)
        a += rows[i]
    end
    vcat(rs...)
end

# Make vcat and hcat work for all TexTables
vcat(t1::TexTable, t2::TexTable) = vcat(convert.(IndexedTable,
                                                 (t1, t2))...)
hcat(t1::TexTable, t2::TexTable) = hcat(convert.(IndexedTable,
                                                 (t1, t2))...)

join_table(t1::IndexedTable) = t1

function join_table(t1::TexTable, t2::TexTable)

    # Promote to the same dimensions
    t1, t2 = promote(convert.(IndexedTable, (t1, t2))...)

    t1_new = add_col_level(t1, 1)
    t2_new = add_col_level(t2, 2)

    return hcat(t1_new, t2_new)
end

function join_table(t1::TexTable, t2::TexTable,
                    t3::TexTable, args...)
    return join_table(join_table(t1,t2), t3, args...)
end

# Joining on Pairs
function join_table(p1::Pair{P1,T1}) where {P1 <: Printable,
                                      T1 <: TexTable}
    t1      = convert(IndexedTable, p1.second)
    t1_new  = add_col_level(p1.second, 1, p1.first)
end

function join_table(p1::Pair{P1,T1}, p2::Pair{P2,T2}) where
    {P1 <: Printable, P2 <: Printable, T1 <: TexTable, T2<:TexTable}

    t1, t2 = promote(convert.(IndexedTable, (p1.second, p2.second))...)

    t1_new = add_col_level(t1, 1, p1.first)
    t2_new = add_col_level(t2, 2, p2.first)

    return hcat(t1_new, t2_new)
end

function join_table(p1::Pair{P1,T1},
              p2::Pair{P2,T2},
              p3::Pair{P3,T3}, args...) where
                {P1 <: Printable, P2 <: Printable, P3<:Printable,
                T1 <: TexTable, T2<:TexTable, T3<:TexTable}

    return join_table(join_table(p1, p2), p3, args...)
end

join_table(t1::IndexedTable, p2::Pair{P2,T2}) where {P2, T2} = begin
    join_table(t1, join_table(p2))
end

join_table(p2::Pair{P2,T2},t1::IndexedTable) where {P2, T2} = begin
    join_table(join_table(p2), t1)
end

# Appending
append_table(t1::TexTable) = t1
function append_table(t1::TexTable, t2::TexTable)

    # Promote to the same dimensions
    t1, t2 = promote(t1, t2)

    t1_new = add_row_level(t1, 1)
    t2_new = add_row_level(t2, 2)

    return vcat(t1_new, t2_new)
end

function append_table(t1::TexTable, t2::TexTable, t3::TexTable, args...)
    return append_table(append_table(t1,t2), t3, args...)
end

# Appending on Pairs
function append_table(p1::Pair{P1,T1}) where {P1 <: Printable,
                                      T1 <: TexTable}
    t1      = convert(IndexedTable, p1.second)
    t1_new  = add_row_level(p1.second, 1, p1.first)
end

function append_table(p1::Pair{P1,T1}, p2::Pair{P2,T2}) where
    {P1 <: Printable, P2 <: Printable, T1 <: TexTable, T2<:TexTable}

    t1, t2 = promote(convert.(IndexedTable, (p1.second, p2.second))...)
    t1_new = add_row_level(t1, 1, p1.first)
    t2_new = add_row_level(t2, 2, p2.first)

    return vcat(t1_new, t2_new)
end

function append_table(p1::Pair{P1,T1},
              p2::Pair{P2,T2},
              p3::Pair{P3,T3}, args...) where
                {P1 <: Printable, P2 <: Printable, P3<:Printable,
                T1 <: TexTable, T2<:TexTable, T3<:TexTable}

    return append_table(append_table(p1, p2), p3, args...)
end

append_table(t1::IndexedTable, p2::Pair{P2,T2}) where {P2, T2} = begin
    append_table(t1, append_table(p2))
end

append_table(p2::Pair{P2,T2},t1::IndexedTable) where {P2, T2} = begin
    append_table(append_table(p2), t1)
end

append_table(t1::IndexedTable, p2::Pair{P2,T2}, args...) where {P2, T2} = begin
    append_table(append_table(t1, p2), args...)
end



################################################################################
#################### Conversion Between Dimensions #############################
################################################################################

function promote_rule(::Type{IndexedTable{N1,M1}},
                      ::Type{IndexedTable{N2,M2}}) where
                      {N1, M1, N2, M2}
    N = max(N1, N2)
    M = max(M1, M2)
    return IndexedTable{N, M}
end

function convert(::Type{IndexedTable{N, M}}, t::IndexedTable{N0, M0}) where
    {N,M,N0,M0}
    if (N0 > N) | (M0 > M)
        msg = """
        Cannot convert IndexedTable{$N0,$M0} to IndexedTable{$N,$M}
        """
        throw(error(msg))
    else
        for i=1:N-N0
            t = add_row_level(t, 1)
        end

        for i=1:M-M0
            t = add_col_level(t, 1)
        end
    end
    return t
end

function promote_rule(::Type{T1}, ::Type{T2}) where
    {T1 <: IndexedTable, T2 <: TexTable}
    return IndexedTable
end

################################################################################
#################### General Indexing ##########################################
################################################################################

function insert_index!(index::Index{N}, idx::TableIndex{N}) where N

    range = searchsorted(index, idx, lt=isless_group)

    # If it's empty, insert it in the right position
    if isempty(range)
        insert!(index, range.start, idx)
        return idx, range.start

    # Otherwise, check to see whether or not the last level matches already
    else

        N_index = get_idx(index[range], N)
        N_names = get_name(index[range], N)

        # If it does, then we don't have to do anything except check that the
        # strings are right
        if idx.name[N] in N_names
            loc = findall(N_names .== idx.name[N])[1]

            # Here's the new index
            new_idx = update_index(idx, tuple(idx.idx[1:N-1]..., loc))
            return new_idx, range.start + loc - 1
        else
            # Otherwise, it's not there so we need to insert it into the index,
            # and its last integer level should be one higher than all the
            # others
            new_idx = update_index(idx, tuple(idx.idx[1:N-1]...,
                                              maximum(N_index)+1))

            insert!(index, range.stop+1, new_idx)
            return new_idx, range.stop + 1
        end
    end
end

get_idx(index)               = map(x->x.idx, index)
get_idx(index, level::Int)   = map(x->x.idx[level], index)
get_name(index)              = map(x->x.name, index)
get_name(index, level::Int)  = map(x->x.name[level], index)

function find_level(index::Index{N}, idx::Idx{N}, level::Int) where N
    range = searchsorted(get_level(index, level), idx[level])
    return range
end

function add_level(index::Vector{TableIndex{N}}, level,
                   name::Printable="") where N
    return map(index) do idx
        return TableIndex(tuple(level, idx.idx...),
                          tuple(Symbol(name), idx.name...))
    end
end

"""
```
add_row_level(t::IndexedTable, level::Int, name::$Printable="")
```
Add's a new level to the row index with the given `level` for the integer
component of the index, and `name` for the symbol component
"""
function add_row_level(t::IndexedTable{N,M}, level::Int,
                       name::Printable="") where {N,M}

    new_rows = add_level(t.row_index, level, name)

    old_new  = Dict(Pair.(t.row_index, new_rows)...)

    new_columns = []
    for col in t.columns
        data = TableDict{N+1, FormattedNumber}()
        for (key, value) in col.data
            data[old_new[key]] = value
        end
        push!(new_columns, TableCol(col.header, data))
    end

    return IndexedTable(new_columns, new_rows, t.col_index)
end

"""
```
add_col_level(t::IndexedTable, level::Int, name::$Printable="")
```
Add's a new level to the column index with the given `level` for the integer
component of the index, and `name` for the symbol component
"""
function add_col_level(t::IndexedTable{N,M},
                       level::Int, name::Printable="") where {N,M}

    new_cols = add_level(t.col_index, level, name)
    old_new  = Dict(Pair.(t.col_index, new_cols))

    new_columns = []
    for col in t.columns
        push!(new_columns, TableCol(old_new[col.header],
                                    col.data))
    end

    return IndexedTable(new_columns, t.row_index, new_cols)
end

add_row_level(t::TexTable, args...) = add_row_level(IndexedTable(t), args...)
add_col_level(t::TexTable, args...) = add_col_level(IndexedTable(t), args...)

################################################################################
#################### Access Methods ############################################
################################################################################

Indexable{N}  = Union{TableIndex{N}, Tuple}
Indexable1D   = Union{Printable, Integer}

function row_loc(t::IndexedTable{N,M}, idx::Indexable{N}) where {N,M}
    locate(t.row_index, idx)
end

function col_loc(t::IndexedTable{N,M}, idx::Indexable{N}) where {N,M}
    locate(t.col_index, idx)
end

function loc(t::IndexedTable{N,M}, ridx::Indexable{N},
             cidx::Indexable{M}) where {N,M}

    rloc = locate(t.row_index, ridx)
    cloc = locate(t.col_index, cidx)

    if isempty(rloc) | isempty(cloc)
        throw(KeyError("key ($ridx, $cidx) not found"))
    elseif length(rloc) > 1
        throw(KeyError("$ridx does not uniquely identify a row"))
    elseif length(cloc) > 1
        throw(KeyError("$cidx does not uniquely identify a column"))
    else
        return rloc[1], cloc[1]
    end
end

function locate(index::Vector{TableIndex{N}}, idx::TableIndex{N}) where N
    return findall(index .== Ref(idx))
end

function locate(index::Vector{TableIndex{N}}, idx) where N
    length(idx) == N || throw(ArgumentError("$idx does not have dimension $N"))
    return findall(index) do x
        for i=1:N
            match_index(x, idx[i], i) || return false
        end
        return true
    end
end

function match_index(index::TableIndex{N}, idx::Printable, level::Int) where N
    return index.name[level] == Symbol(idx)
end

function match_index(index::TableIndex{N}, idx::Int, level::Int) where N
    return index.idx[level] == idx
end

function getindex(t::IndexedTable{N,M}, row::Indexable{N},
                  col::Indexable{M}) where {N,M}
    rloc, cloc = loc(t, row, col)
    return t.columns[cloc][t.row_index[rloc]]
end

function setindex!(t::IndexedTable, args...)
    throw(error("setindex! not implemented yet"))
end

# Fallback Methods
function getindex(t::IndexedTable, row::Indexable1D, col::Indexable1D)
    return t[tuple(row), tuple(col)]
end

function getindex(t::IndexedTable, row::Indexable, col::Indexable1D)
    return t[row, tuple(col)]
end

function getindex(t::IndexedTable, row::Indexable1D, col::Indexable)
    return t[tuple(row), col]
end

# Getvals
function get_vals(t::IndexedTable, row, col)
    get_vals(t[row, col])
end
