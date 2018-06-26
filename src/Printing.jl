########################################################################
#################### Printing ##########################################
########################################################################

import Base: show, size

function getindex(t::IndexedTable, row)
    output = []
    for col in t.columns
        push!(output, col[row])
    end

    return output
end

show(io::IO, col::TableCol) = print(io, IndexedTable(col))

size(t::IndexedTable)= (length(t.row_index), length(t.col_index))

function rowheader_length(t::IndexedTable{N,M}, level::Int) where {N,M}
    row_index = t.row_index
    row_names = get_name(row_index)
    lengths   = map(t.row_index) do idx
        length(string(idx.name[level]))
    end
    return maximum(lengths)
end

function rowheader_length(t::IndexedTable{N,M}) where {N,M}
    # Offset it by one since there's no leading space
    l = -1
    for i=1:N
        l += rowheader_length(t, i) + 3
    end
    return l
end

show(io::IO, t::IndexedTable{N,M}) where {N,M} = begin
    print(io, "IndexedTable{$N,$M}")
end

########################################################################
#################### REPL Output #######################################
########################################################################
function head(t::IndexedTable{1,1})

    # Add Column Names
    output = ""

    l = rowheader_length(t)
    output *= format("{:$l} ", "")
    for col in t.columns
        l = get_length(col)
        output *= "| $(format("{:$l}", string(col.header.name[1]))) "
    end

    # Add a line-break and a horizontal line
    k = length(output)
    output *= "\n"
    output *= "-"^k
    output *= "\n"

    return output
end

function body(t::IndexedTable{1,1})

    # Start the output string
    output = ""

    # Get the row-header length
    l = rowheader_length(t)

    for key in t.row_index
        row = t[key]

        # Print the name

        output *= format("{:>$l} ", string(key.name[1] ))
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

show(io::IO, t::IndexedTable{1,1}) = print(io, head(t)*body(t))
########################################################################
#################### Latex Table Output ################################
########################################################################

function tex_head(t::IndexedTable{1,1})

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

function tex_body(t::IndexedTable{1,1})

    # Start the output string
    output = ""

    # Get the row-header length
    l = rowheader_length(t)

    for key in t.RowHeader
        row = t[key]

        # Print the name
        output *= format("{:>$l} ", string(key) )
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

tex_foot(t::IndexedTable{1,1}) = "\\bottomrule \n\\end{tabular}"

function tex(t::IndexedTable{1,1})
    return prod([tex_head(t), tex_body(t), tex_foot(t)])
end

function write_tex(outfile, t::IndexedTable{1,1})
    open(outfile, "w") do f
        write(f, tex(t))
    end
end


