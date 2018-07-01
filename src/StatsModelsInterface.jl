#=
This file implements StatsModels constructors for TableCols.  That is,
it allows one to pass a StatsModels object directly to the TableCol
constructor (or, since the Table constructor falls back to TableCols on
a vararg, the Table constructor).
=#

varnames(m::LinearModel) = m.pp.X
varnames(m::DataFrameRegressionModel) = coefnames(m.mf)

tt(m::LinearModel)                  = coef(m) ./ stderror(m)
tt(m::DataFrameRegressionModel)     = coef(m) ./ stderror(m)
pval(m::LinearModel)                = ccdf.(FDist(1, dof_residual(m)),
                                            abs2.(tt(m)))
pval(m::DataFrameRegressionModel)   = ccdf.(FDist(1, dof_residual(m)),
                                            abs2.(tt(m)))

function TableCol(header, m::StatisticalModel;
                  stats=(:N=>Int∘nobs, "\$R^2\$"=>r2))

    coef_block = TableCol(header)
    for (name, val, se, pval) in zip(varnames(m), coef(m), stderror(m),
                                      pval(m))
        coef_block[name] = val, se
        0.05 <  pval <= .1  && star!(coef_block[name], 1)
        0.01 <  pval <= .05 && star!(coef_block[name], 2)
                pval <= .01 && star!(coef_block[name], 3)
    end

    stats_pairs = OrderedDict(p.first=>p.second(m) for p in stats)
    stats_block = TableCol(header, stats_pairs)

    return append_table(coef_block, stats_block)
end
