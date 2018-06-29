using RDatasets, TexTables, DataStructures, DataFrames
using StatsModels, GLM

@test "Linear Model Examples" begin
    # Check that this code runs without errors
    df = dataset("datasets", "attitude")
    # Compute summary stats for each variable
    cols = []
    for header in names(df)
        x = df[header]
        stats = TableCol(header,
                         "N"     => length(x),
                         "Mean"  => mean(x),
                         "Std"   => std(x),
                         "Min"   => minimum(x),
                         "Max"   => maximum(x))
        push!(cols, stats)
    end
    tab = hcat(cols...)
    m1 = lm(@formula( Rating ~ 1 + Raises ), df)
    m2 = lm(@formula( Rating ~ 1 + Raises + Learning), df)
    m3 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges), df)
    m4 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                                 + Complaints), df)
    m5 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges
                                 + Complaints + Critical), df)
    reg_table = hcat(TableCol("(1)", m1),
                     TableCol("(2)", m2),
                     TableCol("(3)", m3),
                     TableCol("(4)", m4),
                     TableCol("(5)", m5))
    compare_file(2, reg_table |> to_ascii)
    compare_file(3, reg_table |> to_tex)

    group1 = hcat(  TableCol("(1)", m1),
                    TableCol("(2)", m2),
                    TableCol("(3)", m3))
    compare_file(4, group1 |> to_ascii)
    compare_file(5, group1 |> to_tex)

    group2 = hcat(  TableCol("(1)", m4),
                    TableCol("(2)", m5))
    compare_file(6, group2 |> to_ascii)
    compare_file(7, group2 |> to_tex)

    grouped_table = join_table( "Group 1"=>group1,
                                "Group 2"=>group2)
    compare_file(8, grouped_table |> to_ascii)
    compare_file(9, grouped_table |> to_tex)
end
