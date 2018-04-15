module Tables

# package code goes here
# Nice string formattting
using Formatting

# Import from base to extend
import Base.getindex, Base.setindex!, Base.push!
export TableCol, Table, tex, write_tex

########################################################################
#################### Table Column Type #################################
########################################################################

type TableCol
    header
    keys::Vector{Any}
    values::Vector{Any}
    precision::Vector{Any}
    fmt
end

function TableCol(header, kv::Associative; kwargs...)
    return TableCol(header, collect(keys(kv)), collect(values(kv));
                    kwargs...)
end

function TableCol(header, kv::Associative, kp::Associative; kwargs...)
    throw(MethodError("TableCol does not yet support Associative
                      Precisions"))
end

function TableCol(header, keys, values, precision; 
    fmt="{:.2f}")
    return TableCol(header, keys[:], values[:], precision[:], fmt)
end

function TableCol(header, keys, values; fmt="{:.2f}")
    precision = NaN*zeros(size(values)) 
    return TableCol(header, keys[:], values[:], precision[:], fmt)
end

function getindex(col::TableCol, x, backup="")
    val, se = get_vals(col, x, backup)
    l = get_length(col)
    return format("{:<$l}", val), format("{:<$l}", se)
end


## This function is a real mess.  Need to clean it up
function get_vals(col::TableCol, x, backup="")
    # Returns the formatted value if it exists
    idx = findfirst(col.keys, x)
    if idx > 0
        # Get the value
        raw = col.values[idx]
        if isa(raw, Bool)
            if raw
                val = "Yes"
            else
                val = "No"
            end
        elseif isa(raw, Real)
            val = format(col.fmt, raw)
        elseif isa(raw, AbstractString)
            val = raw
        else
            T = typeof(raw)
            throw(TypeError("Type $T of $raw is unsupported"))
        end

        precision  = col.precision[idx]
        if !all(isnan.(precision))
            se  = "("
            l = length(precision)
            for (i, p) in enumerate(precision)
                se *= format(col.fmt, p)
                se *= i < l ? ", " : ")"
            end
        else
            se = " "
        end
    else
        val = backup
        se  = " "
    end

    return val, se
end

function get_length(col::TableCol)
    # Get all the values
    l = length(String(col.header))
    for key in col.keys
        val, se = get_vals(col, key)
        l = max(l, max(length(val), length(se)))
    end
    return l
end
        


function setindex!(col::TableCol, value, key)
    idx = findfirst(col.keys, key)
    if idx == 0
        push!(col.keys, key)
        push!(col.values, value)
        push!(col.precision, NaN)
    else 
        col.values[idx] = value
    end

    return col
end

function setindex!(col::TableCol, value::Tuple, key)
    idx = findfirst(col.keys, key)
    val, se = value
    if idx == 0
        push!(col.keys, key)
        push!(col.values, val)
        push!(col.precision, se)
    else 
        col.values[idx] = val
        col.precision[idx] = se
    end

    return col
end


########################################################################
#################### Full Table Type ###################################
########################################################################

type Table
    Columns::Vector
    RowHeader::Vector
    ColHeader::Vector
    Table() = new([],[],[])
end

function Table(Columns::Vector, RowHeader::Vector, ColHeader::Vector)
    return Table(Columns, RowHeader, ColHeader)
end

function Table(args...; kwargs...)
    t = Table() 
    for col in args
        push!(t, col)
    end
    return t
end

function push!(t::Table, newcol::TableCol)
    # Add to the list of columns
    push!(t.Columns, newcol)

    # Update the Row Headers
    for key in newcol.keys
        if !(key in t.RowHeader)
            push!(t.RowHeader, key)
        end
    end

    # Update the Column Headers
    push!(t.ColHeader, newcol.header)

    return t
end

function getindex(t::Table, row)
    output = []
    for col in t.Columns
        push!(output, col[row])
    end

    return output
end

Base.show(io::IO, col::TableCol) = print(io, Table(col))

########################################################################
#################### REPL Output #######################################
########################################################################
function head(t::Table)
    
    # Add Column Names
    output = ""
    
    l = rowheader_length(t)
    output *= format("{:$l} ", "")
    for col in t.Columns
        l = get_length(col)
        output *= "| $(format("{:$l}", col.header)) " 
    end
    
    # Add a line-break and a horizontal line
    k = length(output)
    output *= "\n"
    output *= "-"^k
    output *= "\n"
    
    return output

end

function body(t::Table)
    
    # Start the output string
    output = ""
    
    # Get the row-header length
    l = rowheader_length(t)

    for key in t.RowHeader
        row = t[key] 
        
        # Print the name

        output *= format("{:>$l} ", String(key) )
        second  = []
        for (val, se) in row
            output *= "| $val " 
            push!(second, se)
        end

        # New line
        output *= "\n"
        
        # Only print standard errors if it's nonempty
        if !all(isempty.(strip.(second)))
            output *= format("{:>$l} ", " ")
            for se in second
                output *= "| $se "
            end
            # New line
            output *= "\n"
        end
    end

    return output
end

Base.show(io::IO, t::Table) = print(io, head(t)*body(t))
########################################################################
#################### Latex Table Output ################################
########################################################################

function tex_head(t::Table)
    
    # Make Alignment
    align = "r|"
    for col in t.Columns
        align *= "c"
    end

    # Add Column Names
    output = "\\begin{tabular}{$align}\n\\toprule \n"
    
    l = rowheader_length(t)
    output *= format("{:$l} ", "")
    for col in t.Columns
        l = get_length(col)
        output *= "\& $(format("{:$l}", col.header)) "
    end
    
    # Add a line-break and a horizontal line
    output *= "\\\\ \\hline \n"
    
    return output

end

rowheader_length(t::Table) = maximum(length.(String.(t.RowHeader)))

function tex_body(t::Table)
    
    # Start the output string
    output = ""
    
    # Get the row-header length
    l = rowheader_length(t)

    for key in t.RowHeader
        row = t[key] 
        
        # Print the name
        output *= format("{:>$l} ", String(key) )
        second = []
        for (val, se) in row
            output *= "\& $val "
            push!(second, se)
        end

        # New line
        output *= "\\\\ \n"
        
        # Only print standard errors if it's nonempty
        if !all(isempty.(strip.(second)))
            output *= format("{:>$l} ", "")
            for se in second
                output *= "\& $se "
            end
            # New line
            output *= "\\\\ \n"
        end
    end

    return output
end

tex_foot(t::Table) = "\\bottomrule \n\\end{tabular}"

function tex(t::Table)
    return prod([tex_head(t), tex_body(t), tex_foot(t)])
end

function write_tex(outfile, t::Table)
    open(outfile, "w") do f
        write(f, tex(t))
    end
end

end # module
