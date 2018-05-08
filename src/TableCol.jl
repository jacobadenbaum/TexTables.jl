using DataStructures: OrderedDict
Printable = Union{Symbol, String}
TableDict = OrderedDict{Printable, FormattedNumber}

mutable struct TableCol
    header::String
    data::TableDict
    sub::TableDict
end

function TableCol(header::String)
    return TableCol(header, TableDict())
end

TableCol(x::TableCol; kwargs...) = x

########################################################################
#################### Constructors ######################################
########################################################################

function TableCol(header, kv::Associative)
    TableCol(header, 
             TableDict(key=>FormattedNumber(value)
                       for (key, value) in kv))
end

function TableCol(header, kv::Associative, kp::Associative)
    TableCol(header, 
             TableDict(key=>(key in keys(kp)) ? 
                       FormattedNumber(val, kp[key]) :
                       FormattedNumber(val)
                       for (key, val) in kv))
end

function TableCol(header, keys, values)
    TableCol(header,
             TableDict(key=>FormattedNumber(val)
                       for (key, val) in zip(keys, values)))
end

function TableCol(header, keys, values, precision)
    TableCol(header,
             TableDict(key=>FormattedNumber(val, se)
                       for (key, val, se) in zip(keys, values,
                                                 precision)))
end

########################################################################
#################### Indexing ##########################################
########################################################################

function get_vals(col::TableCol, x::Printable, backup="")
    if  x in keys(col.data) 
        val     = value(col.data[x])
        seval   = se(col.data[x]) 
    else
        val     = backup
        seval   = ""
    end
    return  val, seval
end

function getindex(col::TableCol, x, backup="")
    val, se = get_vals(col, x, backup)
    l = get_length(col)
    return format("{:<$l}", val), format("{:<$l}", se)
end

function get_length(col::TableCol)
    # Get all the values
    l = length(String(col.header))
    for key in keys(col.data)
        val, se = get_vals(col, key)
        l = max(l, length(val), length(se))
    end
    return l
end

function setindex!(col::TableCol, value, key)
    col.data[key] = FormattedNumber(value)     
    return col
end

function setindex!(col::TableCol, value::Tuple, key)
    col.data[key] = FormattedNumber(value...)
    return col
end
