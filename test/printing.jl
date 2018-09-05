import TexTables:   get_level, generate_schema, check_table_type,
                    default_sep, schema_lookup

@testset "Extracting Index Levels" begin
    # Standard Composite Tables
    Random.seed!(1234)
    x  = randn(10)
    y  = [Symbol(:key, i) for i=1:10]
    t1 = TableCol("test", y, x)
    t2 = TableCol("test2", y[2:9], x[2:9])
    t3 = TableCol("test3", y, x, randn(10) .|> abs .|> sqrt)
    t4 = TableCol("test" , Dict("Fixed Effects"=>"Yes"))
    t5 = TableCol("test2", Dict("Fixed Effects"=>"No"))
    t6 = TableCol("test3", Dict("Fixed Effects"=>"Yes"))
    c1 = append_table(t1, t4)
    c2 = append_table(t2, t5)
    c3 = append_table(t3, t6)

    # Check that the index levels are what I think they should be:
    @test map(x->get_level(x, 1), c1.row_index) == begin
        Tuple{Int64,Symbol}[(1, Symbol("")), (1, Symbol("")),
                            (1, Symbol("")), (1, Symbol("")),
                            (1, Symbol("")), (1, Symbol("")),
                            (1, Symbol("")), (1, Symbol("")),
                            (1, Symbol("")), (1, Symbol("")),
                            (2, Symbol(""))]
    end

    @test map(x->get_level(x, 2), c1.row_index) == begin
        Tuple{Int64,Symbol}[(1, :key1), (2, :key2), (3, :key3),
                            (4, :key4), (5, :key5), (6, :key6),
                            (7, :key7), (8, :key8), (9, :key9),
                            (10, :key10),
                            (1, Symbol("Fixed Effects"))]
    end

    @test map(x->get_level(x, 1), c1.col_index) == [tuple(1, :test)]
    @test map(x->get_level(x, 1), c2.col_index) == [tuple(1, :test2)]
    @test_throws BoundsError map(x->get_level(x, 2), c1.col_index)
end


@testset "Index Schemas" begin
    # Standard Composite Tables
    Random.seed!(1234)
    x  = randn(10)
    y  = [Symbol(:key, i) for i=1:10]
    t1 = TableCol("test", y, x)
    t2 = TableCol("test2", y[2:9], x[2:9])
    t3 = TableCol("test3", y, x, randn(10) .|> abs .|> sqrt)
    t4 = TableCol("test" , Dict("Fixed Effects"=>"Yes"))
    t5 = TableCol("test2", Dict("Fixed Effects"=>"No"))
    t6 = TableCol("test3", Dict("Fixed Effects"=>"Yes"))
    c1 = append_table(t1, t4)
    c2 = append_table(t2, t5)
    c3 = append_table(t3, t6)

    @test generate_schema(c1.row_index, 1) == Any[(1, Symbol(""))=>10,
                                                  (2, Symbol(""))=>1]
    @test generate_schema(c1.row_index, 2) == begin
        Any[(1, :key1)=>1, (2, :key2)=>1, (3, :key3)=>1, (4, :key4)=>1,
            (5, :key5)=>1, (6, :key6)=>1, (7, :key7)=>1, (8, :key8)=>1,
            (9, :key9)=>1, (10, :key10)=>1, (1, Symbol("Fixed Effects"))=>1]
    end

    @test generate_schema(c3.row_index,1)==generate_schema(c1.row_index,1)
    @test generate_schema(c3.row_index,2)==generate_schema(c1.row_index,2)
    @test_throws BoundsError generate_schema(c3.row_index, 3)

    s = generate_schema(c2.row_index, 1)
    @test schema_lookup(s, 1) == 8
    @test schema_lookup(s, 8) == 8
    @test schema_lookup(s, 9) == 1

    s = generate_schema(c2.row_index, 2)
    @test schema_lookup(s, 1) == 1
    @test schema_lookup(s, 8) == 1
    @test schema_lookup(s, 9) == 1


end

@testset "Argument Checking" begin
    @test check_table_type(:ascii) == nothing
    @test check_table_type(:latex) == nothing
    @test_throws ArgumentError check_table_type(:html)
    @test_throws ArgumentError check_table_type("ascii")
    @test_throws ArgumentError check_table_type("latex")
    @test_throws ArgumentError check_table_type(5)
    @test_throws ArgumentError check_table_type(5.0)
end

@testset "table_type Defaults" begin
    @test default_sep(:ascii) == "|"
    @test default_sep(:latex) == "&"
    @test_throws ArgumentError default_sep("ascii")
end

# c1_a = TableCol("Column 1",
#                 OrderedDict("Row 1"=>1,
#                          "Row 2"=>2.3,
#                          "Row 3"=>(2.3, .3),
#                          "Row 4"=>(832.1, 20.0)))
# c1_b = TableCol("Column 1",
#                 OrderedDict("Stat 1" => 232))
#
# c1   = append_table(c1_a, c1_b)
