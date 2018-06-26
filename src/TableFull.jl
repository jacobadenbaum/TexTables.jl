########################################################################
#################### Full Table Type ###################################
########################################################################

mutable struct Table <: TexTable
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
    for (i, col) in enumerate(args)
        push!(t, TableCol(col; colnum=i, kwargs...))
    end
    return t
end

Table(t::Table) = t

function push!(t::Table, newcol::TableCol)
    # Check that the names are unique
    if newcol.header in t.ColHeader
        msg = "Column Names within a Table must be unique"
        throw(ArgumentError(msg))
    end

    # Add to the list of columns
    push!(t.Columns, newcol)

    # Update the Row Headers
    for key in keys(newcol.data)
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

function get_col(t::Table, col::Union{Int, NTuple{1, T}}) where T
    return t.Columns[col[1]]
end

Base.show(io::IO, col::TableCol) = print(io, Table(col))

row_keys(t::Table) = t.RowHeader
col_keys(t::Table) = t.ColHeader

Base.size(t::Table)= (length(row_keys(t)), length(col_keys(t)))

########################################################################
#################### Pre-Printing ######################################
########################################################################

function preprint(t::Table)

    s = Matrix{AbstractString}(dims(t)...)

    for (j, col) in enumerate(t.Columns)
        for (i, row)  in enumerate(row_keys(t))
            s[i,j] = col[row]
        end
    end
    return s
end

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

