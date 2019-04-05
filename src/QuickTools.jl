########################################################################
#################### Summary Tables ####################################
########################################################################

count(x) = mapreduce(y->1, +, x)
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
    types = unique(typeof(val) for val in x)
    T     = reduce(promote_type, types)
    return Array{T,N}
end

function summarize(df::AbstractDataFrame, fields=names(df);
                   detail=false, stats=default_stats(detail), kwargs...)

    # Determine whether each column is numeric or not
    numeric = Dict(header => typeof(df[header]) <: NumericCol
                   for header in fields)
    cols = TableCol[]
    for pair in tuplefy(stats)
        col = TableCol(pair.first)
        for header in fields
            if numeric[header]
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
        push!(tabs, string(idx)=>tab)
    end

    return append_table(tabs...)
end

########################################################################
#################### Cross Tabulations #################################
########################################################################



function tabulate(df::AbstractDataFrame, field::Symbol)

    # Count the number of observations by `field`
    tab = by(df, field, _N = field => length)

    # Construct a Frequency Column
    sort!(tab, field)
    vals  = tab[field] .|> Symbol
    freq  = tab[:_N]
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

function tabulate(df::AbstractDataFrame, field1::Symbol, field2::Symbol)

    # Count the number of observations by `field`
    fields = vcat(field1, field2)
    df     = dropmissing(df[fields], disallowmissing=true)
    tab = by(df, fields, _N = field1 => length)
    sort!(tab, [field1, field2])

    # Put it into wide form
    tab = unstack(tab, field1, field2, :_N)

    # Construct the table
    vals = Symbol.(sort(unique(df[field2])))
    cols = []
    for val in vals
        col  = TableCol(val, Vector(tab[field1]), tab[val])
        col2 = TableCol(val, "Total" => sum(coalesce.(tab[val], 0)))
        push!(cols, append_table(field1=>col, ""=>col2))
    end

    sums = sum(coalesce.(Matrix(tab[vals]), 0), dims=2) |> vec
    tot1 = TableCol("Total", Vector(tab[field1]), sums)
    tot2 = TableCol("Total", "Total" => sum(sums))
    tot  = append_table(field1=>tot1, ""=>tot2)

    ret  = join_table(field2=>hcat(cols...), tot)
end
