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

for (block, fname) in zip([:1,:2,:3], [:addcoef!, :addmeta!, :addstats!])

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

    @eval function ($fname)(t::RegCol, ps::Associative; level=1, name="")
        ($fname)(t, ps...)
    end
end

########################################################################
#################### Linear Model Interface ############################
########################################################################

varnames(m::LinearModel) = m.pp.X
varnames(m::DataFrameRegressionModel) = coefnames(m.mf)

tt(m::LinearModel)                  = coef(m) ./ stderror(m)
tt(m::DataFrameRegressionModel)     = coef(m) ./ stderror(m)
pval(m::LinearModel)                = ccdf.(FDist(1, dof_residual(m)),
                                            abs2.(tt(m)))
pval(m::DataFrameRegressionModel)   = ccdf.(FDist(1, dof_residual(m)),
                                            abs2.(tt(m)))

RegModel = Union{LinearModel, DataFrameRegressionModel}
function TableCol(header, m::RegModel;
                  stats=(:N=>Int∘nobs, "\$R^2\$"=>r2))

    col = RegCol(header)

    # Add the coefficients
    for (name, val, se, pval) in zip(varnames(m), coef(m), stderror(m),
                                      pval(m))
        addcoef!(col, name, val, se)
        0.05 <  pval <= .1  && star!(col[name], 1)
        0.01 <  pval <= .05 && star!(col[name], 2)
                pval <= .01 && star!(col[name], 3)
    end

    # Add in the fit statistics
    addstats!(col, OrderedDict(p.first=>p.second(m) for p in stats))

    return col
end


########################################################################
#################### regtable Interface ###############################
########################################################################

TableAble = Union{RegModel, TexTable, Pair, Tuple}

function regtable(args::Vararg{TableAble}; num=1)
    cols = TexTable[]
    for arg in args
        new_tab = regtable(arg; num=num)
        n, m = size(new_tab)
        num += m
        push!(cols, new_tab)
    end
    return hcat(cols...)
end

function regtable(t::RegModel; num=1)
    return TableCol("($num)", t)
end

function regtable(t::TexTable; num=1)
    return t
end

function regtable(p::Pair; num=1)
    return join_table(p.first=>regtable(p.second, num=num))
end

function regtable(p::Tuple; num=1)
    return regtable(p...; num=num)
end
