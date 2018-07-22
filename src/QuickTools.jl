########################################################################
#################### Summary Tables ####################################
########################################################################

count(x) = sum(map(y->1, x))
p10(x) = quantile(x |> collect, .1)
p25(x) = quantile(x |> collect, .25)
p50(x) = quantile(x |> collect, .50)
p75(x) = quantile(x |> collect, .75)
p90(x) = quantile(x |> collect, .9)

function default_stats(detail::Bool)
    if !detail
        return ("Obs"         => count ∘ skipmissing,
                "Mean"        => mean ∘ skipmissing,
                "Std. Dev."   => std ∘ skipmissing,
                "Min"         => minimum ∘ skipmissing,
                "Max"         => maximum ∘ skipmissing)
    else
        return ("Obs"         => count ∘ skipmissing,
                "Mean"        => mean ∘ skipmissing,
                "Std. Dev."   => std ∘ skipmissing,
                "Min"         => minimum ∘ skipmissing,
                "p10"         => p10 ∘ skipmissing,
                "p25"         => p25 ∘ skipmissing,
                "p50"         => p50 ∘ skipmissing,
                "p75"         => p75 ∘ skipmissing,
                "p90"         => p90 ∘ skipmissing,
                "Max"         => maximum ∘ skipmissing)
    end
end

NumericCol = AbstractVector{T} where {T1<:Real, T2<:Real,
                                      T<:Union{T1, Union{T2, Missing}}}

tuplefy(x) = tuple(x)
tuplefy(x::Tuple) = x

function promotearray(x::AbstractArray{S, N}) where {S,N}
    types = typeof.(x) |> unique
    T     = promote_type(types...)
    return Array{T,N}
end

function summarize(df::AbstractDataFrame, fields=names(df);
                   detail=false, stats=default_stats(detail), kwargs...)

    cols = TableCol[]
    for pair in tuplefy(stats)
        col = TableCol(pair.first)
        for header in fields
            if promotearray(df[header]) <: NumericCol
                col[header] = pair.second(df[header])
            else
                col[header] = ""
            end
        end
        push!(cols, col)
    end

    return hcat(cols...)
end

function summarize(df::AbstractDataFrame, field::Symbol; kwargs...)
    summarize(df, vcat(field); kwargs...)
end

function summarize_by(df, byname::Symbol,
                      fields=setdiff(names(df), vcat(byname));
                      kwargs...)
    tabs = []
    gd = groupby(df, byname)
    for sub in gd
        tab = summarize(sub, fields; kwargs...)
        vals= unique(sub[byname])
        length(vals) == 1 || throw(error("Groupby isn't working"))
        idx = vals[1]
        push!(tabs, idx=>tab)
    end

    return append_table(tabs...)
end

########################################################################
#################### Cross Tabulations #################################
########################################################################

function tabulate(df::AbstractDataFrame, field)

    # Count the number of observations by `field`
    tab = by(df, field) do d
        return DataFrame(N=count(d[field]))
    end

    # Construct a Frequency Column
    sort!(tab, field)
    vals  = tab[field] .|> Symbol
    freq  = tab[:N]
    pct   = freq/sum(freq)*100
    cum   = cumsum(pct)

    # Construct Table
    col1 = append_table(TableCol("Freq.",    vals, freq),
                        TableCol("Freq.", "Total"=>sum(freq)))
    col2 = append_table(TableCol("Percent",  vals, pct ),
                        TableCol("Percent", "Total"=>sum(pct)))
    col3 = TableCol("Cum.",     vals, cum )
    col = hcat(col1, col2, col3)
end


