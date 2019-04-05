#=
This file implements StatsModels constructors for TableCols.  That is,
it allows one to pass a StatsModels object directly to the TableCol
constructor (or, since the Table constructor falls back to TableCols on
a vararg, the Table constructor).
=#

########################################################################
#################### General Regression API Implementation #############
########################################################################

RegCol{M} = TableCol{3,M}

function RegCol(header::Printable)
    return TableCol(TableIndex(1, header), TableDict{3, FormattedNumber}())
end

"""
```
getnext(t::TableCol{3,M}, group::Int, level::Int) where M
```
In a TableCol `t` of row depth 3, computes the next index on the third level
given that the first dimension of the index is `group` and the second is
`level`.
"""
function getnext(t::RegCol, group::Int, level::Int)
    max_idx = 0
    for ridx in keys(t.data)
        ridx.idx[1] != group && continue
        ridx.idx[2] != level && continue
        max_idx = max(max_idx, ridx.idx[3])
    end
    return max_idx + 1
end

const block_labs = Dict(:setcoef! =>"Coefficient",
                        :setmeta! =>"Metadata",
                        :setstats! =>"Statistics")

for (block, fname) in zip([:1,:2,:3], [:setcoef!, :setmeta!, :setstats!])

    """
    ```
    $fname(t::$RegCol, key, val[, se]; level=1, name="")
    $fname(t::$RegCol, key=>val; level=1, name="")
    $fname(t::$RegCol, kv::AbstractDict)
    ```
    Inserts into `t` a key/value pair (possibly with a standard error) within
    the block.  Like the `TableCol` constructor, the pairs can be passed as
    either individual key/value[/se] tuples or pairs, as several vectors of
    key/value[/se] pairs, or as an associative.

    To add additional sub-blocks, use the `level` keyword argument.  Integers
    less than 0 will appears in blocks above the standard block, and integers
    greater than 1 will appear below it.

    To name the block or sub-block, pass a nonempty string as the `name` keyword
    argument.
    """
    @eval function ($fname)(t::RegCol, key::Printable, val; level=1, name="")
        next_idx = getnext(t, $block, level)
        index    = TableIndex(($block, level, next_idx), ("", name, key))
        t[index] = val
    end

    @eval function ($fname)(t::RegCol, key::Printable, val, se; level=1, name="")
        next_idx = getnext(t, $block, level)
        index    = TableIndex(($block, level, next_idx), ("", name, key))
        t[index] = val, se
    end

    @eval function ($fname)(t::RegCol, p::Pair; level=1, name="")
        next_idx = getnext(t, $block, level)
        key      = p.first
        val      = p.second
        index    = TableIndex(($block, level, next_idx), ("", name, key))
        t[index] = val
    end

    # Handle associatives
    @eval function ($fname)(t::RegCol, args...)
        for kv in zip(args)
            ($fname)(t, kv...)
        end
    end

    @eval function ($fname)(t::RegCol, ps::AbstractDict; level=1, name="")
        ($fname)(t, ps...)
    end
end

########################################################################
#################### Linear Model Interface ############################
########################################################################

function TableCol(header, m::RegressionModel;
                  stats=(:N=>Int∘nobs, "\$R^2\$"=>r2),
                  meta=(), stderror::Function=StatsBase.stderror, kwargs...)

    # Compute p-values
    pval(m) = ccdf.(FDist(1, dof_residual(m)),
                    abs2.(coef(m)./stderror(m)))

    # Initialize the column
    col  = RegCol(header)

    # Add the coefficients
    for (name, val, se, p) in zip(coefnames(m), coef(m), stderror(m), pval(m))
        setcoef!(col, name, val, se)
        0.05 <  p <= .1  && star!(col[name], 1)
        0.01 <  p <= .05 && star!(col[name], 2)
                p <= .01 && star!(col[name], 3)
    end

    # Add in the fit statistics
    setstats!(col, OrderedDict(p.first=>p.second(m) for p in tuplefy(stats)))

    # Add in the metadata
    setmeta!(col, OrderedDict(p.first=>p.second(m) for p in tuplefy(meta)))

    return col
end


########################################################################
#################### regtable Interface ###############################
########################################################################

TableAble = Union{RegressionModel, TexTable, Pair, Tuple}

function regtable(args::Vararg{TableAble}; num=1, kwargs...)
    cols = TexTable[]
    for arg in args
        new_tab = regtable(arg; num=num, kwargs...)
        n, m = size(new_tab)
        num += m
        push!(cols, new_tab)
    end
    return hcat(cols...)
end

function regtable(t::RegressionModel; num=1, kwargs...)
    return TableCol("($num)", t; kwargs...)
end

function regtable(t::TexTable; kwargs...)
    return t
end

function regtable(p::Pair; kwargs...)
    return join_table(p.first=>regtable(p.second; kwargs...))
end

function regtable(p::Tuple; kwargs...)
    return regtable(p...; kwargs...)
end
