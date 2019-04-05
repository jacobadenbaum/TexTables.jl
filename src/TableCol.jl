Idx{N}      = NTuple{N, Int}
Name{N}     = NTuple{N, Symbol}

struct TableIndex{N}
    idx::Idx{N}
    name::Name{N}
end
Index{N}    = Vector{TableIndex{N}}
Printable   = Union{String, Symbol}

function TableIndex(idx, name)
    return TableIndex(tuplefy(idx), tuplefy(Symbol.(name)))
end

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

TableCol(header::Printable) = TableCol(TableIndex(1, header),
                                    TableDict{1, FormattedNumber}())

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

function TableCol(header::Printable, kv::AbstractDict)
    pairs = collect(TableIndex(i, key)=>FormattedNumber(value)
                    for (i, (key, value)) in enumerate(kv))
    TableCol(header,
             OrderedDict{TableIndex{1}, FormattedNumber}(pairs))
end

function TableCol(header, kv::AbstractDict, kp::AbstractDict)
    TableCol(header,
             OrderedDict{TableIndex{1}, FormattedNumber}(
                TableIndex(i, key)=>(key in keys(kp)) ?
                                    FormattedNumber(val, kp[key]) :
                                    FormattedNumber(val)
                                    for (i, (key, val))
                                    in enumerate(kv)))
end

function TableCol(header, ks::Vector, vs::Vector)

    pairs = [TableIndex(i, key)=>FormattedNumber(val)
             for (i, (key, val)) in enumerate(zip(ks, vs))]
    TableCol(header,
             OrderedDict{TableIndex{1}, FormattedNumber}(pairs...))
end

function TableCol(header, keys::Vector, values::Vector,
                  precision::Vector)

    pairs  = [ TableIndex(i, key)=>FormattedNumber(val, se)
               for (i, (key, val, se))
               in enumerate(zip(keys, values, precision))]
    data = OrderedDict(pairs...)
    return TableCol(header, data)
end

convert(::Type{FormattedNumber}, x) = FormattedNumber(x)
convert(::Type{FormattedNumber}, x::FormattedNumber) = x

Entry = Pair{T, K} where {T<:Printable, K<:Union{Printable, Number, Missing,
                                                 NTuple{2,Number}}}
function TableCol(header::Printable, pairs::Vararg{Entry})
    return TableCol(header, OrderedDict(pairs))
end

########################################################################
#################### Indexing ##########################################
########################################################################

function get_vals(x::FormattedNumber)
    val     = value(x)
    seval   = se(x)
    star    = "*"^x.star
    return val, seval, star
end

function get_vals(col::TableCol, x::TableIndex, backup="")
    if  x in keys(col.data)
        return get_vals(col.data[x])
    else
        return backup, "", ""
    end
end

# This is an inefficient backup getindex method to maintain string
# indexing for users
function getindex(col::TableCol, key::Printable)

    x   = Symbol(key)
    loc = name_lookup(col, x)
    index = keys(col.data) |> collect

    if length(loc) > 1
        throw(KeyError("""
           The string keys you've provided are not unique.  Try indexing
           by TableIndex instead.
           """))
    else
        return col[index[loc[1]]]
    end
end

function name_lookup(col::TableCol{N,M}, x::Symbol) where {N,M}
    index = keys(col.data) |> collect
    names = get_name(index, N)
    return  findall(y->y==x, names)
end

function getindex(col::TableCol, x::TableIndex)
    if haskey(col.data, x)
        return col.data[x]
    else
        return FormattedNumber("")
    end
end

function setindex!(col::TableCol{1,N}, value, key::Printable) where N
    skey        = Symbol(key)
    loc         = name_lookup(col, skey)
    col_index   = keys(col.data) |> collect
    if length(loc) > 1
        throw(KeyError("""
           The string keys you've provided are not unique.  Try indexing
           by TableIndex instead.
           """))
    elseif length(loc) == 0
        # We need to insert it at a new position
        index   =   get_idx(col_index, 1)
        new_idx =   length(index) > 0  ?
                    maximum(index) + 1 :
                    1
        col[TableIndex(new_idx, skey)] = value
    else
        col[col_index[loc[1]]] = value
    end
end

# General Backup falls back to FormattedNumber constructor
function setindex!(col::TableCol, value, key::TableIndex)
    col.data[key] = FormattedNumber(value)
    return col
end

# Handle values passed with precision
function setindex!(col::TableCol, value::Tuple{T, T2}, key::TableIndex) where
    {T, T2<:AbstractFloat}
    col.data[key] = FormattedNumber(value)
    return col
end

# Handle optional stars
function setindex!(col::TableCol, value::Tuple{T, T2, Int},
                   key::TableIndex) where {T, T2<:AbstractFloat}
    col.data[key] = FormattedNumber(value[1:2])
    star!(col.data[key], value[3])
    return col
end

function size(t::TableCol)
    n = length(t.data)
    return n, 1
end
