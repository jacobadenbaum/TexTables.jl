
"""
Internal function.

Checks `table_type` argument for validity, and throws error if not in
list of valid values.
"""
check_table_type(table_type) = begin
    table_type in [:ascii, :latex] && return

    msg = """
    $table_type is invalid argument for table_type.  See
    documentation for `TablePrinter`:

    table_type::Symbol (default :ascii)
        Controls which type of table is printed.  Currently has
        two options:
        1.  :ascii -- Prints an ASCII table to be displayed in
            the REPL
        2.  :latex -- Prints a LaTeX table for output
    """
    throw(ArgumentError(msg))
end

default_sep(table_type) = begin
    check_table_type(table_type)
    table_type == :ascii && return "|"
    table_type == :latex && return "&"
end

@with_kw mutable struct TableParams
    pad::Int            = 1
    table_type::Symbol  = :ascii
    se_pos::Symbol      = :below
    star::Bool          = true
    sep::String         = default_sep(table_type)
    align::String       = "c"
    TableParams(pad, table_type, se_pos, star, sep, align) = begin
        # Argument Checking
        return new(pad, table_type, se_pos, star, sep, align)
    end
end

mutable struct TablePrinter{N,M}
    table::IndexedTable{N,M}
    params::TableParams
    col_schema
    row_schema
end

"""
```
TablePrinter(table::IndexedTable{N,M}; kwargs...) where {N,M}
```
Maps out the column and row schemas, and constructs a `TablePrinter`
object for the given table.  Additional option parameters can be passed
as keyword arguments

Parameters
----------
pad::Int (default 1)
    The number of spaces to pad the separator characters on each side.
table_type::Symbol (default :ascii)
    Controls which type of table is printed.  Currently has two options:
    1.  :ascii -- Prints an ASCII table to be displayed in the REPL
    2.  :latex -- Prints a LaTeX table for output
"""
function TablePrinter(t::TexTable; kwargs...)
    table      = convert(IndexedTable, t)
    col_schema = generate_schema(table.col_index)
    row_schema = generate_schema(table.row_index)
    params     = TableParams(;kwargs...)

    return TablePrinter(table, params, col_schema, row_schema)
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

"""
```
get_lengths(t::TablePrinter, col_schema=generate_schema(t.table.col_index))
```
Internal function.

Returns a vector of column lengths to be used in printing the table.
Has the same length as `t.columns`.  `col_schema` will be generated by
default if not passed.  It must be the output of
`generate_schema(t.col_index)`.

If any header requires more printing space than the columns themselves
would require, allocates the additional space equally among all the
columns it spans.
"""
function get_lengths(printer::TablePrinter{N,M},
                     col_schema=generate_schema(
                        printer.table.col_index)) where {N,M}

    # Get the underlying table and some parameters
    t   = printer.table
    pad = printer.params.pad
    sep = printer.params.sep

    # Start out with the assumption that we just need enough space for
    # the column contents
    k       = length(t.columns)
    lengths = col_length.(Ref(printer), t.columns)

    # Initialize a Block-Width Schema
    bw_schema = Dict()

    # Repeat this code twice so that everything updates fully
    for u = 1:2

    # Loop through the levels of the column index from the bottom up
    for i=M:-1:1
        level_schema = printer.col_schema[i]
        col_pos = 0
        bw_schema[i] = []

        for (s, p) in enumerate(level_schema)
            pos, name   = p.first
            block_size  = p.second
            fname       = format_name(printer, i, block_size, name)

            # Figure out the block width, accounting for the extra
            # space from the separators and the padding
            block_width = sum(lengths[(1:block_size) .+ col_pos])
            block_width+= (block_size-1)*(2*pad + length(sep))

            # If the block is not big enough for the formatted name,
            # then add extra whitespace to each column (evenly) until
            # there's enough.
            difference = length(fname) - block_width
            if difference > 0
                extra_space = div(difference, block_size)
                remainder   = rem(difference, block_size)
                for j = (1:block_size) .+ col_pos
                    lengths[j] += extra_space
                    if j <= remainder & u == 1
                        lengths[j] += 1
                    end
                end
            end

            # Add the block width to the block width schema
            push!(bw_schema[i], max(block_width, length(fname)))

            # Update the column position
            col_pos += block_size
        end
    end
    end

    return lengths, bw_schema
end

########################################################################
#################### Printer Methods ###################################
########################################################################

"""
```
mc(cols, val="", align="c")
"""
function mc(cols, val="", align="c")
    return "\\multicolumn{$cols}{$align}{$val}"
end

function format_name(printer::TablePrinter{N,M}, level::Int,
                     block_size::Int, name)::String where {N,M}
    # ASCII tables just print the centered name
    printer.params.table_type == :ascii && return string(name)

    # LaTeX tables need to print the name in a multi-column environment
    # except at the lowest level
    if printer.params.table_type == :latex
        # When printing the name in Latex, we may want to escape some characters
        name = escape_latex(printer, name)

        if level == M
            return "$name"
        else
            align = printer.params.align
            return mc(block_size, name, align)
        end
    end
end

function align_name(printer::TablePrinter, len, name)
    @unpack table_type = printer.params

    table_type == :ascii && return center(name, len)
    table_type == :latex && return format("{:$len}", name)
end

escape_latex(p::TablePrinter, name) = escape_latex(name)

function escape_latex(name)
    # Convert the name to a string
    name = string(name)

    # Keep track of whether we're in math mode
    mathmode = false

    i = 1
    while i < length(name)
        # Update whether we're in mathmode
        if name[i] == '$'
            mathode = mathmode ? false : true
        end

        s = name[i]
        if (name[i] in keys(latex_replacements)) & !mathmode
            r    = latex_replacements[s]
            name = name[1:i-1] * r * name[i+1:end]
            i += length(r)
        elseif (name[i] in keys(mathmode_replacements)) & mathmode
            r    = mathmode_replacements[s]
            name = name[1:i-1] * r * name[i+1:end]
            i += length(r)
        else
            i += 1
        end

    end
    return name
end

const latex_replacements    = Dict{Char, String}('_' => "\\_")
const mathmode_replacements = Dict{Char, String}()

"""
Returns the maximum length of the column entries, not accounting for the
header columns
"""
function col_length(p::TablePrinter, col::TableCol)
    @unpack pad, se_pos, star = p.params
    l = 0
    for key in keys(col.data)
        val, se, stars = get_vals(col, key)
        sl  = star ? length(stars) : 0
        if se_pos == :below
            l = max(l, length(val) + sl, length(se))
        elseif se_pos == :inline
            l = max(l, length(val) + sl + pad + length(se))
        elseif se_pos == :none
            l = max(l, length(val) + sl)
        end
    end
    return l
end

function newline(p::TablePrinter)
    @unpack table_type = p.params
    table_type == :ascii && return ""
    table_type == :latex && return "\\\\"
end

endline(p::TablePrinter) = "\n"

# subline not properly implemented yet
subline(p::TablePrinter, args...) = ""

function hline(p::TablePrinter)
    @unpack table_type = p.params
    table_type == :ascii && return "\n"*"-"^width(p)
    table_type == :latex && return " \\hline"
end

function hline(p::TablePrinter{N,M}, i::Int) where {N,M}
    t       = p.table
    n, m    = size(t)

    # Figure out what kind of line ending we're on
    i <   0     && return ""
    i ==  0     && return hline(p)
    if 0 < i < n
        ridx1       = t.row_index[i]
        ridx2       = t.row_index[i+1]
        return new_group(ridx1, ridx2, N-1) ? hline(p) : ""
    elseif i == n
        return ""
    else
        msg = "There are only $n rows.  $i is not a valid index"
        throw(BoundsError(msg))
    end
end

function width(p::TablePrinter)
    @unpack pad, sep = p.params
    sep_len = length(sep)
    lengths = get_lengths(p)[1]
    rh_len  = rowheader_length(p)
    pad_ws  = " "^pad

    # Compute Total Width
    len     = 0
    len    += rh_len + pad
    len    += sum(lengths)
    len    += map(x->2*pad + sep_len, lengths) |> sum
end

function top_matter(printer::TablePrinter{N,M}) where {N,M}
    @unpack table_type = printer.params
    @unpack col_schema = printer
    t = printer.table

    table_type == :ascii && return ""
    table_type == :latex && return begin
        align = ""
        for i=1:N
            align *= empty_row(t, i) ? "" : "r"
        end

        for (i, pair) in enumerate(col_schema[max(M-1,1)])
            align *= (M > 1) | (i==1) ? "|" : ""
            align *= "c"^pair.second
        end

        return "\\begin{tabular}{$align}\n\\toprule\n"
    end
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

########################################################################
#################### Header Printing ###################################
########################################################################

function head(printer::TablePrinter{N,M}) where {N,M}

    t       = printer.table
    pad     = printer.params.pad
    pad_ws  = " "^pad
    sep     = printer.params.sep
    sep_len = length(sep)

    # Get the column lengths, column schema, block width schema, and
    # rowheader length
    lengths, bw_schema  = get_lengths(printer)
    col_schema          = printer.col_schema
    rh_length           = rowheader_length(printer)

    # Handle any top matter
    output  = ""
    output *= top_matter(printer)

    for i=1:M
        # Skip this iteration in the loop if the column-level is empty
        empty_col(t, i) && continue

        # Add whitespace to account for the rowheader length, and add a
        # separator
        for j=1:N
            rhj     = rowheader_length(printer, j)
            empty_row(t, j) && continue
            output *= format("{:$rhj}", "")
            output *= j < N ? pad_ws * sep * pad_ws : pad_ws
        end

        # Write each header
        for (s, pair) in enumerate(col_schema[i])
            block_len   = bw_schema[i][s]
            block_size  = pair.second
            name        = pair.first[2]
            name        = format_name(printer, i, block_size, name)
            header      = align_name(printer, block_len, name)

            # Write the header to the output
            output     *= sep * pad_ws * header * pad_ws
        end

        output *= newline(printer)
        output *= hline(printer,   -M + i)
        output *= subline(printer, -M + i)
        output *= endline(printer)
    end

    return output
end

########################################################################
#################### Body Printing #####################################
########################################################################

"""
```
empty_se(t::IndexedTable, ridx)
```
Internal printing function.

Computes for an indexed table `t` whether or not any of the entries
corresponding to row index `ridx` have nonempty standard errors.
"""
function empty_se(t::IndexedTable, ridx)
    n, m = size(t)
    for j=1:m
        cidx          = t.col_index[j]
        val, se, star = get_vals(t, ridx, cidx)
        isempty(se) || return false
    end
    return true
end

function body(printer::TablePrinter{N,M}) where {N,M}
    output = ""
    n, m = size(printer.table)
    for i=1:n
        output *= printline(printer, i)
        output *= newline(printer)
        output *= subline(printer, i)
        output *= hline(printer, i)
        output *= endline(printer)
    end
    return output
end

function printline(printer::TablePrinter, i)
    i >= 1  || throw(ArgumentError("$i is an invalid row number"))
    t       =  printer.table
    n, m    =  size(t)
    pad     =  printer.params.pad
    pad_ws  =  " "^pad
    sep     =  printer.params.sep
    sep_len =  length(sep)

    @unpack se_pos, star  =  printer.params

    # Get the column lengths, column schema, block width schema, and
    # rowheader length
    lengths, bw_schema  = get_lengths(printer)

    # Start writing the lines
    output   = ""
    output  *= rowheader(printer, i)
    ridx     = t.row_index[i]
    print_se = !empty_se(t, ridx)
    inline   = se_pos == :inline
    below    = se_pos == :below
    if below & print_se
        line2= rowheader(printer, i, empty=true)
    end

    for j = 1:m
        cidx    = t.col_index[j]
        val, se, stars = get_vals(t, ridx, cidx)

        # Are we printing the standard errors?
        use_se  = inline & print_se

        # Format and Print the value
        output  *= sep * pad_ws
        entry    = val
        entry   *= star ? stars : ""
        entry   *= use_se       ?
                   pad_ws * se  :
                   ""
        output  *= format("{:>$(lengths[j])}",entry) * pad_ws

        if below & print_se
            line2 *= sep * pad_ws
            line2 *= format("{:>$(lengths[j])}",se)
            line2 *= pad_ws
        end
    end

    if below & print_se
        output *= newline(printer)*endline(printer)
        output *= line2
    end
    return output
end

function rowheader(printer::TablePrinter{N,M}, i; empty=false) where {N,M}
    t       =  printer.table
    pad     =  printer.params.pad
    pad_ws  =  " "^pad
    sep     =  printer.params.sep
    sep_len =  length(sep)
    ridx    =  t.row_index

    output  = ""
    for j = 1:N
        # Check whether they're all empty
        empty_row(t, j) && continue

        # Otherwise, figure out if we need to print it this time round
        no_check    = (i == 1) | (j == N)
        print_name  = no_check ? true : new_group(ridx[i],ridx[i-1], j)

        # Print the separator and the padding
        output *= ((j==1) || empty_row(t, j-1))  ? "" : sep * pad_ws

        # Get length of rowheader for formatting
        len     = rowheader_length(printer, j)

        # Print the name or whitespace depending on `print_name`
        if print_name & !empty
            # Check the size of the row if we're printing
            block_size  = schema_lookup(printer.row_schema[j], i)

            # Add the row to the output
            name    = ridx[i].name[j]
            output *= format("{:>$len}",
                             format_row_name(printer, j, block_size,
                                             name))
        else
            output *= format("{:>$len}", "")
        end

        # Print the final padding
        output *= pad_ws
    end
    return output
end

function schema_lookup(schema, i)

    # Cumulative count sum
    counts  = map(x->x.second, schema) |> cumsum

    # Find insertion point for i
    idx     = searchsortedfirst(counts, i)

    # Return the block size at that point
    return schema[idx].second
end

function format_row_name(printer::TablePrinter{N,M}, level::Int,
                         block_size::Int, name)::String where {N,M}
    @unpack table_type = printer.params

    if table_type == :ascii
        fname = string(name)
    elseif table_type == :latex
        # When printing the name in Latex, we may want to escape some characters
        sname = escape_latex(printer, name)
        fname =  block_size == 1 ?  sname : mr(block_size,sname)
    end
    return string(fname)
end

"""
```
mr(rows, val="", align="c")
"""
function mr(cols, val="")
    return "\\multirow{$cols}{*}{$val}"
end


########################################################################
#################### Footer ############################################
########################################################################

function foot(t::TablePrinter)
    @unpack table_type = t.params
    table_type == :ascii && return ""
    table_type == :latex && return "\\bottomrule\n\\end{tabular}"
end


########################################################################
#################### Printing ##########################################
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

function getindex(t::IndexedTable, row)
    output = []
    for col in t.columns
        push!(output, col[row])
    end

    return output
end

show(io::IO, col::TableCol) = print(io, IndexedTable(col))

size(t::IndexedTable)= (length(t.row_index), length(t.col_index))

function rowheader_length(printer::TablePrinter, level::Int)
    t           = printer.table
    row_index   = t.row_index
    row_names   = get_name(row_index)
    row_schema  = printer.row_schema[level]
    n, m        = size(t)

    # Compute the max length
    l = 0
    for i=1:n
        idx = t.row_index[i]
        name  = idx.name[level]
        bsize = schema_lookup(row_schema, i)
        fname = format_row_name(printer, level, bsize, name)
        l = max(l, length(fname))
    end
    return l
end

"""
```
rowheader_length(printer::TablePrinter [, level::Int])
```
Computes the full length of the row-header.  If level is specified, it
computes the length of just the one level.  If no level is specified, it
computes the sum of all the level lengths, accounting for padding and
separator characters.
"""
function rowheader_length(printer::TablePrinter{N,M}) where {N,M}
    # Unpack
    t           = printer.table
    pad         = printer.params.pad
    sep         = printer.params.sep
    sep_len     = length(sep)
    total_pad   = 2*pad + sep_len

    # Offset it by one since there's no leading space
    l = -total_pad
    for i=1:N
        lh = rowheader_length(printer, i)
        l += lh
        l += lh > 0 ? total_pad : 0
    end
    return l
end

########################################################################
#################### REPL Output #######################################
########################################################################

function print(io::IO, p::TablePrinter)
    print(io, head(p)*body(p)*foot(p))
end

function print(io::IO, t::IndexedTable{N,M}; kwargs...) where {N,M}
    if all(size(t) .> 0)
        # Construct the printer
        printer = TablePrinter(t; kwargs...)
        print(io, printer)
    else
        print(io, "IndexedTable{$N,$M} of size $(size(t))")
    end
end

function print(t::IndexedTable; kwargs...)
    print(stdout, t; kwargs...)
end

show(io::IO, t::IndexedTable; kwargs...) = print(io, t; kwargs...)
show(t::IndexedTable; kwargs...) = print(t; kwargs...)

########################################################################
#################### String Output Methods #############################
########################################################################

function to_ascii(t::IndexedTable; kwargs...)
    any(size(t) .== 0) && throw(error("Can't export empty table"))
    p= TablePrinter(t; table_type = :ascii, kwargs...)
    return head(p)*body(p)*foot(p)
end

function to_tex(t::IndexedTable; kwargs...)
    any(size(t) .== 0) && throw(error("Can't export empty table"))
    p = TablePrinter(t; table_type = :latex, kwargs...)
    return head(p)*body(p)*foot(p)
end

########################################################################
#################### Latex Table Output ################################
########################################################################

function write_tex(outfile, t::IndexedTable)
    open(outfile, "w") do f
        write(f, to_tex(t))
    end
end
