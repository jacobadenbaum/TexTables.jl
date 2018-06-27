using   TexTables
import  TexTables:  TableIndex, TableDict
using   DataStructures
using   Base.Test

@testset "Constructing TableCols" begin
    @testset "Integer Values" begin
        # Data
        name = "test"
        x = ["key1", "key2", "key3"]
        y = [1, 2, 3]

        # Simple way to construct it
        col = TableCol(name, x, y)
        @test col isa TableCol{1,1}

        # Check that all the constructors work
        col2 = TableCol(name, OrderedDict(Pair.(x,y)))
        @test col2 == col
    end

    @testset "Float Values" begin
        # Data
        name = "test"
        x = ["key1", "key2", "key3"]
        y = [1.0, 2.0, 3.0]
        p = [.2, .3, .3]

        # Simple way to construct it
        col = TableCol(name, x, y)
        @test col isa TableCol{1,1}

        # Check that all the constructors work
        col2 = TableCol(name, OrderedDict(Pair.(x,y)))
        @test col2 == col

        # Check that we can construct it with the precision in there

    end
end

########################################################################
#################### Composite Tests ###################################
########################################################################

@testset "Full Table Tests" begin
    # Baseline check
    srand(1234)
    x  = randn(10)
    y  = [Symbol(:key, i) for i=1:10]
    t1 = TableCol("test", y, x) |> IndexedTable
    t2 = TableCol("test2", y[2:9], x[2:9]) |> IndexedTable
    t3 = TableCol("test3", y, x, randn(10) .|> abs .|> sqrt) |> IndexedTable
    sub_tab1= hcat(t1, t2, t3)

    # Composite Table Checks
    t4 = TableCol("test" , Dict("Fixed Effects"=>"Yes")) |> IndexedTable
    t5 = TableCol("test2", Dict("Fixed Effects"=>"No"))  |> IndexedTable
    t6 = TableCol("test3", Dict("Fixed Effects"=>"Yes")) |> IndexedTable

    # Build the table two different ways
    sub_tab2= hcat(t4, t5, t6)
    tab     = vcat(sub_tab1, sub_tab2)
    tab2    = [t1 t2 t3
               t4 t5 t6]
    @test sprint(show, tab) == sprint(show, tab2)

    c1 = append_table(t1, t4)
    c2 = append_table(t2, t5)
    c3 = append_table(t3, t6)

    test_string = """
        \\begin{tabular}{r|ccc}
        \\toprule
              & test   & test2  & test3   \\\\ \\hline
         key1 & 0.867  &        & 0.867   \\\\
              &        &        & (0.749) \\\\
         key2 & -0.902 & -0.902 & -0.902  \\\\
              &        &        & (0.139) \\\\
         key3 & -0.494 & -0.494 & -0.494  \\\\
              &        &        & (0.358) \\\\
         key4 & -0.903 & -0.903 & -0.903  \\\\
              &        &        & (1.361) \\\\
         key5 & 0.864  & 0.864  & 0.864   \\\\
              &        &        & (0.910) \\\\
         key6 & 2.212  & 2.212  & 2.212   \\\\
              &        &        & (0.332) \\\\
         key7 & 0.533  & 0.533  & 0.533   \\\\
              &        &        & (0.501) \\\\
         key8 & -0.272 & -0.272 & -0.272  \\\\
              &        &        & (0.608) \\\\
         key9 & 0.502  & 0.502  & 0.502   \\\\
              &        &        & (0.269) \\\\
        key10 & -0.517 &        & -0.517  \\\\
              &        &        & (1.226) \\\\
        \\bottomrule
        \\end{tabular}"""
    @test tex(sub_tab1) == test_string
end
