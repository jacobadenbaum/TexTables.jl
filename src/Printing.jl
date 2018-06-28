@with_kw mutable struct TableParams
    pad::Int=3
end


mutable struct TablePrinter{N,M}
    table::IndexedTable{N,M}
    params::TableParams
    col_length
    col_schema
    row_schema
end
function TablePrinter(table::IndexedTable{N,M}; kwargs...) where {N,M}

    col_schema = generate_schema(table.col_index)
    row_schema = generate_schema(table.row_index)
    col_length = get_lengths(table, col_schema)
    params     = TableParams(;kwargs...)

    return TablePrinter(table, params, col_length, col_schema,
                        row_schema)
end

########################################################################
#################### Index Schemas #####################################
########################################################################

"""
```
new_group(idx1::TableIndex, idx2::TableIndex, level::Int)
```
Internal method. Compares two elements from an index (of type
`Index{N}`) and checks whether or not `idx2` is in a different group
than `idx1` at index-depth `level`.  An index starts a new group if
either its numeric position has changed, or the string value has
changed.

Calls itself recursively on each level above the given level to see
whether or not we have a new group at any of the higher levels.
"""
function new_group(idx1::TableIndex{N}, idx2::TableIndex{N},
                   level::Int) where N

    # Terminal case
    level == 0 && return false

    # In other levels, recurse backwards through the levels -- short
    # circuiting if we find any level where we're switching to a new
    # group
    return new_group(idx1, idx2, level-1) || begin
        same_num    = idx1.idx[level]  == idx2.idx[level]
        same_name   = idx1.name[level] == idx2.name[level]
        return (!same_num) | (!same_name)
    end
end

"""
```
get_level(idx::$Idx, i)
```
Extracts the `i`th level of the index `idx` (both the integer and name
component) and returns it as a tuple.
"""
get_level(idx::TableIndex, i) = idx.idx[i], idx.name[i]

"""
```
generate_schema(index::$Index [, level::Int])
```
Returns a vector of `Pair{Tuple{Int, Symbol},Int}`, where for each
`pair`, `pair.first` is a tuple of the positional and symbolic
components of the index level, and `pair.second` is the number of times
that this entry is repeated within `level`.

When called without a level specified, returns an `OrderedDict` of
`level=>generate_schema(index, level)` for each level.

Example
-------
If we had a column `c1` that looked like
```
julia> show(c1)
              |  test
-----------------------
         key1 | 0.867
         key2 | -0.902
         key3 | -0.494
         key4 | -0.903
         key5 | 0.864
         key6 | 2.212
         key7 | 0.533
         key8 | -0.272
         key9 | 0.502
        key10 | -0.517
-----------------------
Fixed Effects | Yes
```
Then `generate_schema` would return:
```
julia> generate_schema(c2.row_index, 1)
2-element Array{Any,1}:
 (1, Symbol(""))=>8
 (2, Symbol(""))=>1

julia> generate_schema(c2.row_index, 2)
9-element Array{Any,1}:
 (1, :key2)=>1
 (2, :key3)=>1
 (3, :key4)=>1
 (4, :key5)=>1
 (5, :key6)=>1
 (6, :key7)=>1
 (7, :key8)=>1
 (8, :key9)=>1
 (1, Symbol("Fixed Effects"))=>1
```
"""
function generate_schema(index::Index{N}, level::Int) where N
    # Argument Checking
    1 <= level <= N || throw(BoundsError("$level is invalid level"))

    # Initialize the level schema
    level_schema    = []
    idx             = get_level(index[1], level)
    count           = 1

    # Loop through the index values
    n       = length(index)
    for i = 1:n-1
        # If the next index is new, push it to the list
        if new_group(index[i], index[i+1], level)
            push!(level_schema, idx=>count)
            idx     = get_level(index[i+1], level)
            count   = 1
        else
            count  += 1
        end
    end
    push!(level_schema, idx=>count)
    return level_schema
end

function generate_schema(index::Index{N}) where N
    return OrderedDict(i=>generate_schema(index, i) for i=1:N)
end

########################################################################
#################### Printing ##########################################
########################################################################

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

function rowheader_length(t::IndexedTable{N,M}; pad=3) where {N,M}
    # Offset it by one since there's no leading space
    l = -pad
    for i=1:N
        lh = rowheader_length(t, i)
        l += lh
        l += lh > 0 ? pad : 0
    end
    return l
end

########################################################################
#################### REPL Output #######################################
########################################################################

function center(str::String, width::Int)

    l = length(str)
    if l > width
        return str
    else
        k   = div(width - l, 2)
        str = format("{:>$(l + k)}", str)
        str = format("{:<$width}", str)
        return str
    end
end

center(str::Symbol, width::Int) = center(string(str), width)

function head(t::IndexedTable{N,M}) where {N,M}

    # Add Column Names
    output = ""

    for i=1:M
        # Check that this level has nonempty names
        names = get_name(t.col_index, i)
        if !all(isempty.(string.(names)))
            l = rowheader_length(t, pad=1)
            output *= format("{:$l} ", "")

            # Now start handling the headers:
            l = 0

            for (j, col) in enumerate(t.columns)
                # Add this column's length in
                l = l + get_length(col) + 3

                if j < length(t.columns)
                    # Check whether or not we're moving to a new column
                    # group on the next column
                    idx1        = t.col_index[j]
                    idx2        = t.col_index[j+1]
                    print_flag  = new_group(idx1, idx2, i)
                else
                    print_flag  = true
                end

                # If we are, print_flag the full header centered above its
                # columns and move on
                if print_flag
                    output *= "|"
                    output *= center(col.header.name[i], l-1)
                    l = 0
                end
            end
            output *= "\n"
        end
    end

    # Add a line-break and a horizontal line
    k = maximum(length.(split(output, "\n")))
    output *= "-"^k
    output *= "\n"

    return output
end

function body(t::IndexedTable{N,M}) where {N,M}

    # Start the output string
    output = ""

    # Get the row-header length
    lh = [rowheader_length(t,i) for i=1:N]
    l  = rowheader_length(t, pad=1)
    for (i, key)  in enumerate(t.row_index)
        row = t[key]
        if i > 1
            idx2 = t.row_index[i-1]

            # If it's a new row-group, then print a horizontal line
            if new_group(idx2, key, N-1)
                k = maximum(length.(split(head(t), "\n")))
                output *= "-"^k
                output *= "\n"
            end
        end

        print_flag = false

        # Print the name
        for j=1:N
            # Check if we're at a new linegroup
            if i == 1
                print_flag = true
            else
                print_flag = new_group(idx2, key, j)
            end

            # Put in the appropriate output
            name    =   string(key.name[j])
            output *=   print_flag & !empty_row(t,j)  ?
                        format("{:>$(lh[j])} ", name) :
                        ! empty_row(t, j)             ?
                        format("{:>$(lh[j])} ", "")   :
                        ""
        end

        # Print the first line
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

show(io::IO, t::IndexedTable{N,M}) where {N,M} = begin
    if all(size(t) .> 0)
        print(io, head(t)*body(t))
    else
        print(io, "IndexedTable{$N,$M} of size $(size(t))")
    end
end


########################################################################
#################### Latex Table Output ################################
########################################################################

function mc(cols, val="", align="c")
    return "\\multicolumn{$cols}{$align}{$val}"
end

"""
Count the number of non-empty row-index dimensions
"""
function nonempty_rows(t::IndexedTable{N,M}) where {N,M}
    c = 0
    for i=1:N
        c += empty_row(t, i) ? 0 : 1
    end
    return c
end

"""
Check whether the row index in dimension `i` is empty
"""
function empty_row(t::IndexedTable{N,M}, i::Int) where {N,M}
    names = get_name(t.row_index, i)
    return all(isempty.(string.(names)))
end

"""
Check whether the col index in dimension `i` is empty
"""
function empty_col(t::IndexedTable{N,M}, i::Int) where {N,M}
    names = get_name(t.col_index, i)
    return all(isempty.(string.(names)))
end

function tex_head(t::IndexedTable{N,M}) where {N,M}

    # Make Alignment
    align = ""
    for i=1:N
        align *= empty_row(t, i) ? "" : "r"
    end
    align *= "|"

    for (i, col) in enumerate(t.columns)
        align *= "c"
        if i < length(t.columns)
            idx1 = t.col_index[i]
            idx2 = t.col_index[i+1]
            if new_group(idx1, idx2, M-1)
                align *= "|"
            end
        end
    end

    # Add Column Names
    output = "\\begin{tabular}{$align}\n\\toprule\n"

    for i=1:M
        # Check that this level has nonempty names
        if ! empty_col(t, i)
            l = rowheader_length(t)
            output *= format("{:$l} ", "")

            # Now start handling the headers:
            l = 0
            c = 0

            for (j, col) in enumerate(t.columns)
                # Add this column's length in
                l = l + get_length(col) + 2
                c = c + 1

                if j < length(t.columns)
                    # Check whether or not we're moving to a new column
                    # group on the next column
                    idx1        = t.col_index[j]
                    idx2        = t.col_index[j+1]
                    print_flag  = new_group(idx1, idx2, i)
                else
                    print_flag  = true
                end

                # If we are, print_flag the full header centered above its
                # columns and move on
                if print_flag
                    output *= "\& "
                    name    = string(col.header.name[i])
                    if c > 1
                        output *= format("{:<$(l-1)}", mc(c, name))
                    else
                        output *= format("{:<$(l-1)}", name)
                    end

                    l = 0
                    c = 0
                end
            end
            if i < M
                output *= "\\\\\n"
            else

                output *= "\\\\ \\hline\n"
            end
        end
    end

    return output
end

function tex_body(t::IndexedTable{N,M}) where {N,M}

    # Start the output string
    output = ""

    # Get the row-header length
    lh = [rowheader_length(t,i) for i=1:N]
    l  = rowheader_length(t)
    for (i, key)  in enumerate(t.row_index)
        row = t[key]
        if i > 1
            idx2 = t.row_index[i-1]

            # If it's a new row-group, then print a horizontal line
            if new_group(idx2, key, N-1)
                c1 = nonempty_rows(t) + 1
                c2 = c1 + length(t.columns) - 1
                cline = "\\cline{$c1-$c2}"
                hline = "\\hline"
                line  = hline
                output *= "\\\\ $line\n"
            else
                output *= "\\\\\n"
            end
        end

        print_flag = false

        # Print the name
        for j=1:N
            # Check if we're at a new linegroup
            if i == 1
                print_flag = true
            else
                print_flag = new_group(idx2, key, j)
            end

            # Put in the appropriate output
            name    =   string(key.name[j])
            output *=   print_flag & !empty_row(t,j)  ?
                        format("{:>$(lh[j])} ", name) :
                        ! empty_row(t, j)             ?
                        format("{:>$(lh[j]+2)} ", "")   :
                        ""
            if (j < N) & print_flag & !empty_row(t,j)
                output *= "\& "
            end

        end

        # Print the first line
        second  = []
        for (val, se) in row
            output *= "\& $val "
            push!(second, se)
        end

        # Only print standard errors if it's nonempty
        if !all(isempty.(strip.(second)))
            # New line
            output *= "\\\\\n"

            # Print Standard Errors
            output *= format("{:>$l} ", " ")
            for se in second
                output *= "\& $se "
            end
        end
    end

    return output
end

tex_foot(t::IndexedTable) = "\\\\\n\\bottomrule\n\\end{tabular}"

function tex(t::IndexedTable)
    return prod([tex_head(t), tex_body(t), tex_foot(t)])
end

function write_tex(outfile, t::IndexedTable)
    open(outfile, "w") do f
        write(f, tex(t))
    end
end
