@testset "Table Joins for Several Pairs" begin
    import TexTables: IndexedTable, TableCol, join_table
    # Tests for issue in PR #28 (makes sure that the recursive table join
    # implementation on pairs works properly)
    n = 5
    keys = ["x$i" for i in 1:5]
    cols = Vector{IndexedTable{1,1}}(undef, 4)
    for j in 1:4
        cols[j] = hcat(TableCol("mean", keys, rand(n)),
                       TableCol("std", keys, rand(n)))
    end
    
    # Test that the construction doesn't error out with 4 pairs
    for k in 1:4
        @test begin
            tab = join_table(collect("($j)" => cols[j] for j in 1:k)...)
            true
        end
    end
end