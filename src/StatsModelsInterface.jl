#=
This file implements StatsModels constructors for TableCols.  That is,
it allows one to pass a StatsModels object directly to the TableCol
constructor (or, since the Table constructor falls back to TableCols on
a vararg, the Table constructor).  
=#

using StatsBase
using GLM: LinearModel
using StatsModels: DataFrameRegressionModel

varnames(m::LinearModel) = m.pp.X
varnames(m::DataFrameRegressionModel) = m.mf.terms.terms


function TableCol(m::StatisticalModel;
                  colnum=1, 
                  stats=(:N=>Int∘nobs, "\$R^2\$"=>r2))
    col = TableCol("($colnum)", varnames(m), coef(m), stderr(m))
    for pair in stats
        col[pair.first] = pair.second(m)
    end
    return col
end
