using TexTables, DataStructures, DataFrames
using StatsModels, GLM, RDatasets

@testset "Linear Model Examples No Stars" begin
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
    compare_file(2, to_ascii(reg_table, star=false))
    compare_file(3, to_tex(reg_table, star=false))

    # Check that regtable interface works
    reg_table_b = regtable(m1, m2, m3, m4, m5)
    compare_file(2, to_ascii(reg_table_b, star=false))
    compare_file(3, to_tex(reg_table_b, star=false))

    group1 = hcat(  TableCol("(1)", m1),
                    TableCol("(2)", m2),
                    TableCol("(3)", m3))
    compare_file(4, to_ascii(group1, star=false))
    compare_file(5, to_tex(group1, star=false))

    group2 = hcat(  TableCol("(1)", m4),
                    TableCol("(2)", m5))
    compare_file(6, to_ascii(group2, star=false))
    compare_file(7, to_tex(group2, star=false))

    grouped_table = join_table( "Group 1"=>group1,
                                "Group 2"=>group2)
    compare_file(8, to_ascii(grouped_table, star=false))
    compare_file(9, to_tex(grouped_table, star=false))

    # Check that regtable interface works
    grouped_table_b = regtable("Group 1"=>regtable(m1, m2, m3),
                               "Group 2"=>regtable(m4, m5))
    compare_file(8, to_ascii(grouped_table_b, star=false))
    compare_file(9, to_tex(grouped_table_b, star=false))

    grouped_table_c = regtable("Group 1"=>(m1, m2, m3),
                               "Group 2"=>(m4, m5))
    compare_file(32, to_ascii(grouped_table_c, star=false))
    compare_file(33, to_tex(grouped_table_c, star=false))

    # Compare against the original table for group1 again (to make sure
    # that all the join_methods are non-mutating)
    compare_file(4, to_ascii(group1, star=false))
    compare_file(5, to_tex(group1, star=false))
end

@testset "Linear Models With Stars" begin
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
    compare_file(22, to_ascii(reg_table, star=true))
    compare_file(23, to_tex(reg_table, star=true))

    # Check that regtable interface works
    reg_table_b = regtable(m1, m2, m3, m4, m5)
    compare_file(22, to_ascii(reg_table_b, star=true))
    compare_file(23, to_tex(reg_table_b, star=true))

    group1 = hcat(  TableCol("(1)", m1),
                    TableCol("(2)", m2),
                    TableCol("(3)", m3))
    compare_file(24, to_ascii(group1, star=true))
    compare_file(25, to_tex(group1, star=true))

    group2 = hcat(  TableCol("(1)", m4),
                    TableCol("(2)", m5))
    compare_file(26, to_ascii(group2, star=true))
    compare_file(27, to_tex(group2, star=true))

    grouped_table = join_table( "Group 1"=>group1,
                                "Group 2"=>group2)
    compare_file(28, to_ascii(grouped_table, star=true))
    compare_file(29, to_tex(grouped_table, star=true))

    # Check that regtable interface works
    grouped_table_b = regtable("Group 1"=>regtable(m1, m2, m3),
                               "Group 2"=>regtable(m4, m5))
    compare_file(28, to_ascii(grouped_table_b, star=true))
    compare_file(29, to_tex(grouped_table_b, star=true))

    grouped_table_c = regtable("Group 1"=>(m1, m2, m3),
                               "Group 2"=>(m4, m5))
    compare_file(30, to_ascii(grouped_table_c, star=true))
    compare_file(31, to_tex(grouped_table_c, star=true))

    # Compare against the original table for group1 again (to make sure
    # that all the join_methods are non-mutating)
    compare_file(24, to_ascii(group1, star=true))
    compare_file(25, to_tex(group1, star=true))
end

@testset "Summary Tables" begin
    iris = dataset("datasets", "iris")

    sum1 = summarize(iris)
    compare_file(10, to_ascii(sum1))
    compare_file(11, to_tex(sum1))


    sum2 = summarize(iris, detail=true)
    compare_file(12,to_ascii(sum2))
    compare_file(13, to_tex(sum2))

    sum3 = summarize_by(iris, :Species)
    compare_file(14, to_ascii(sum3))
    compare_file(15, to_tex(sum3))

    sum4 = summarize_by(iris, :Species, detail=true)
    compare_file(16, to_ascii(sum4))
    compare_file(17, to_tex(sum4))

    sum5 = tabulate(iris, :Species)
    compare_file(18, to_ascii(sum5))
    compare_file(19, to_tex(sum5))

    sum6 = tabulate(iris, :PetalWidth)
    compare_file(20, to_ascii(sum6))
    compare_file(21, to_tex(sum6))
end
