import Base: isless, ==

Idx{N}      = NTuple{N, Int}
Name{N}     = NTuple{N, Symbol}

struct TableIndex{N}
    idx::Idx{N}
    name::Name{N}
end
Index{N}    = Vector{TableIndex{N}}
Printable   = Union{String, Symbol}

TableIndex(idx::Integer, name::Printable) = begin
    TableIndex(tuple(idx), tuple(Symbol(name)))
end

TableIndex(name::Printable) = TableIndex(1, name)
function update_index(index::TableIndex{N}, new_idx::Idx{N}) where N
    return TableIndex(new_idx, index.name)
end

TableDict{N, T} = OrderedDict{TableIndex{N}, T} where T <: FormattedNumber

########################################################################
#################### Sorting the Index #################################
########################################################################

function isless(index1::TableIndex{N}, index2::TableIndex{N}) where N
    for i=1:N
        # First Check the numeric index
        if index1.idx[i] < index2.idx[i]
            return true
        elseif index1.idx[i] > index2.idx[i]
            return false
        # Then check the strings
        elseif index1.name[i] < index2.name[i]
            return true
        elseif index1.name[i] > index2.name[i]
            return false
        end
    end
    return false
end

function isless_group(index1::TableIndex{N}, index2::TableIndex{N},
                     level=N-1) where N
    for i = 1:N-1
        # First Check the numeric index
        if index1.idx[i] < index2.idx[i]
            return true
        elseif index1.idx[i] > index2.idx[i]
            return false
        # Then check the strings
        elseif index1.name[i] < index2.name[i]
            return true
        elseif index1.name[i] > index2.name[i]
            return false
        end
    end
    return false
end



########################################################################
#################### Columns ###########################################
########################################################################

mutable struct TableCol{N,M} <: TexTable
    header::TableIndex{M}
    data::TableDict{N, FormattedNumber}
end

function TableCol(header::String)
    return TableCol(header, TableDict())
end

TableCol(x::TableCol; kwargs...) = x

function TableCol(header::Printable, kv::TableDict{N,T}) where
    {N,T<:FormattedNumber}
    return TableCol(TableIndex(header),
                    convert(TableDict{N, FormattedNumber}, kv))
end

# Columns are equal if they are the same entry all the way down
==(t1::TableCol, t2::TableCol) = begin
    t1.header == t2.header || return false
    t1.data   == t2.data   || return false
    return true
end

########################################################################
#################### Constructors ######################################
########################################################################

function TableCol(header::Printable, kv::Associative)
    pairs = collect(TableIndex(i, key)=>FormattedNumber(value)
                    for (i, (key, value)) in enumerate(kv))
    TableCol(header,
             OrderedDict{TableIndex{1}, FormattedNumber}(pairs))
end

function TableCol(header, kv::Associative, kp::Associative)
    TableCol(header,
             OrderedDict(TableIndex(i, key)=>(key in keys(kp)) ?
                         FormattedNumber(val, kp[key]) :
                         FormattedNumber(val)
                         for (i, (key, val)) in enumerate(kv)))
end

function TableCol(header, keys, values)

    pairs = [TableIndex(i, key)=>FormattedNumber(val)
             for (i, (key, val)) in enumerate(zip(keys, values))]
    TableCol(header, OrderedDict(pairs...))
end

function TableCol(header, keys, values, precision)

    pairs  = [ TableIndex(i, key)=>FormattedNumber(val, se)
               for (i, (key, val, se))
               in enumerate(zip(keys, values, precision))]
    data = OrderedDict(pairs...)
    return TableCol(header, data)
end

########################################################################
#################### Indexing ##########################################
########################################################################

function get_vals(col::TableCol, x::TableIndex, backup="")
    if  x in keys(col.data)
        val     = value(col.data[x])
        seval   = se(col.data[x])
    else
        val     = backup
        seval   = ""
    end
    return  val, seval
end

# This is an inefficient backup getindex method to maintain string
# indexing for users
function getindex(col::TableCol{1,N}, key::Printable, backup="") where N

    x   = Symbol(key)
    loc = name_lookup(col, x)
    index = keys(col.data) |> collect

    if length(loc) > 1
        throw(KeyError("""
           The string keys you've provided are not unique.  Try indexing
           by TableIndex instead.
           """))
    elseif length(loc) == 0
        return backup
    else
        return col[index[loc[1]], backup]
    end
end

function name_lookup(col::TableCol{1,N}, x::Symbol) where N
    index = keys(col.data)
    idxs  = get_idx(index, 1)
    names = get_name(index, 1)
    return  find(names .== x)
end

function getindex(col::TableCol, x::TableIndex, backup="")
    val, se = get_vals(col, x, backup)
    l = get_length(col)
    return format("{:<$l}", val), format("{:<$l}", se)
end

function get_length(col::TableCol)
    # Get all the values
    l = maximum(length.(string.(col.header.name)))
    for key in keys(col.data)
        val, se = get_vals(col, key)
        l = max(l, length(val), length(se))
    end
    return l
end

function setindex!(col::TableCol{1,N}, value, key::Printable) where N
    skey        = Symbol(key)
    loc         = string_lookup(col, skey)
    col_index   = keys(col.data) |> collect
    if length(loc) > 1
        throw(KeyError("""
           The string keys you've provided are not unique.  Try indexing
           by TableIndex instead.
           """))
    elseif length(loc) == 0
        # We need to insert it at a new position
        index   = get_idx(col_index, 1)
        new_idx = maximum(index) + 1
        col[TableIndex(new_idx, skey)] = value
    else
        col[col_index[loc[1]]] = value
    end
end

function setindex!(col::TableCol, value, key::TableIndex)
    col.data[key] = FormattedNumber(value)
    return col
end
