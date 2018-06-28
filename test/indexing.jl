
@testset "getindex" begin
    @testset "TableCol Indexing" begin
        # Data
        name = "test"
        data = OrderedDict("key1"=>1,
                           "key2"=>2,
                           "key3"=>.5,
                           "key4"=>(.25, .1),
                           "key5"=>"foo")
        # Simple way to construct it
        col = TableCol(name, data)

        # Indexing Returns a Tuple of Formatted Values and Precisions
        @test strip.(col["key1"]) == ("1", "")
        @test strip.(col["key2"]) == ("2", "")
        @test strip.(col["key3"]) == ("0.500", "")
        @test strip.(col["key4"]) == ("0.250", "(0.100)")
        @test strip.(col["key5"]) == ("foo", "")

        # Indexing with Symbols
        @test strip.(col[:key1]) == ("1", "")
        @test strip.(col[:key2]) == ("2", "")
        @test strip.(col[:key3]) == ("0.500", "")
        @test strip.(col[:key4]) == ("0.250", "(0.100)")
        @test strip.(col[:key5]) == ("foo", "")

        # Check that all of the indexed values have the same length
        index = keys(data) |> collect
        vals  = [col[key] for key in index]
        lens  = map(x->length.(x), vals)
        @test all(map(x->x==lens[1], lens))
    end

    @testset "IndexedTable Indexing" begin

        # Construct some random tables
        srand(1234)
        x  = randn(10)
        y  = [Symbol(:key, i) for i=1:10]
        t1 = Table("test", y, x)
        t2 = Table("test2", y[2:9], x[2:9])
        t3 = Table("test3", y, x, randn(10) .|> abs .|> sqrt)
        sub_tab1= hcat(t1, t2, t3)

        # Composite Table Checks
        t4 = Table("test" , Dict("Fixed Effects"=>"Yes"))
        t5 = Table("test2", Dict("Fixed Effects"=>"No"))
        t6 = Table("test3", Dict("Fixed Effects"=>"Yes"))
        c1 = append_table(t1, t4)
        c2 = append_table(t2, t5)
        c3 = append_table(t3, t6)

        @test strip.(c1[ (1, :key1 ), "test"] )  == ("0.867" , "")
        @test strip.(c1[ (1, :key2 ), "test"] )  == ("-0.902", "")
        @test strip.(c1[ (1, :key3 ), "test"] )  == ("-0.494", "")
        @test strip.(c1[ (1, :key4 ), "test"] )  == ("-0.903", "")
        @test strip.(c1[ (1, :key5 ), "test"] )  == ("0.864" , "")
        @test strip.(c1[ (1, :key6 ), "test"] )  == ("2.212" , "")
        @test strip.(c1[ (1, :key7 ), "test"] )  == ("0.533" , "")
        @test strip.(c1[ (1, :key8 ), "test"] )  == ("-0.272", "")
        @test strip.(c1[ (1, :key9 ), "test"] )  == ("0.502" , "")
        @test strip.(c1[ (1, :key10), "test"] )  == ("-0.517", "")
        @test strip.(c1[(2, "Fixed Effects"), "test"]) == ("Yes", "")

        # Check that indexing into the second column we constructed
        # works as expected
        @test strip.(c2[ (1, :key2 ), "test2"] )  == ("-0.902", "")
        @test strip.(c2[ (1, :key3 ), "test2"] )  == ("-0.494", "")
        @test strip.(c2[ (1, :key4 ), "test2"] )  == ("-0.903", "")
        @test strip.(c2[ (1, :key5 ), "test2"] )  == ("0.864" , "")
        @test strip.(c2[ (1, :key6 ), "test2"] )  == ("2.212" , "")
        @test strip.(c2[ (1, :key7 ), "test2"] )  == ("0.533" , "")
        @test strip.(c2[ (1, :key8 ), "test2"] )  == ("-0.272", "")
        @test strip.(c2[ (1, :key9 ), "test2"] )  == ("0.502" , "")
        @test strip.(c2[(2, "Fixed Effects"), "test2"]) == ("No", "")
        @test_throws KeyError c2[ (1, :key1 ), "test2"]
        @test_throws KeyError c2[ (1, :key10), "test2"]

        # Check that indexing with the wrong header throws an error
        @test_throws KeyError c2[ (1, :key2), "test" ]

        # Check that indexing into the wrong block throws an error
        @test_throws KeyError c2[ (1, "Fixed Effects"), "test2"]

        # Check that indexing into IndexedTables works with standard
        # errors
        @test strip.(c3[(1,:key1 ), "test3"]) == ("0.867" , "(0.749)")
        @test strip.(c3[(1,:key2 ), "test3"]) == ("-0.902", "(0.139)")
        @test strip.(c3[(1,:key3 ), "test3"]) == ("-0.494", "(0.358)")
        @test strip.(c3[(1,:key4 ), "test3"]) == ("-0.903", "(1.361)")
        @test strip.(c3[(1,:key5 ), "test3"]) == ("0.864" , "(0.910)")
        @test strip.(c3[(1,:key6 ), "test3"]) == ("2.212" , "(0.332)")
        @test strip.(c3[(1,:key7 ), "test3"]) == ("0.533" , "(0.501)")
        @test strip.(c3[(1,:key8 ), "test3"]) == ("-0.272", "(0.608)")
        @test strip.(c3[(1,:key9 ), "test3"]) == ("0.502" , "(0.269)")
        @test strip.(c3[(1,:key10), "test3"]) == ("-0.517", "(1.226)")

        # Check that indexing into merged tables works right
        tab = [c1 c2 c3]
        @test strip.(tab[ (1, :key1 ), "test"] )  == ("0.867" , "")
        @test strip.(tab[ (1, :key2 ), "test"] )  == ("-0.902", "")
        @test strip.(tab[ (1, :key3 ), "test"] )  == ("-0.494", "")
        @test strip.(tab[ (1, :key4 ), "test"] )  == ("-0.903", "")
        @test strip.(tab[ (1, :key5 ), "test"] )  == ("0.864" , "")
        @test strip.(tab[ (1, :key6 ), "test"] )  == ("2.212" , "")
        @test strip.(tab[ (1, :key7 ), "test"] )  == ("0.533" , "")
        @test strip.(tab[ (1, :key8 ), "test"] )  == ("-0.272", "")
        @test strip.(tab[ (1, :key9 ), "test"] )  == ("0.502" , "")
        @test strip.(tab[ (1, :key10), "test"] )  == ("-0.517", "")
        @test strip.(tab[(2, "Fixed Effects"), "test"]) == ("Yes", "")

        # Check that indexing into the second column we constructed
        # works as expected
        @test strip.(tab[ (1, :key2 ), "test2"] )  == ("-0.902", "")
        @test strip.(tab[ (1, :key3 ), "test2"] )  == ("-0.494", "")
        @test strip.(tab[ (1, :key4 ), "test2"] )  == ("-0.903", "")
        @test strip.(tab[ (1, :key5 ), "test2"] )  == ("0.864" , "")
        @test strip.(tab[ (1, :key6 ), "test2"] )  == ("2.212" , "")
        @test strip.(tab[ (1, :key7 ), "test2"] )  == ("0.533" , "")
        @test strip.(tab[ (1, :key8 ), "test2"] )  == ("-0.272", "")
        @test strip.(tab[ (1, :key9 ), "test2"] )  == ("0.502" , "")
        @test strip.(tab[(2, "Fixed Effects"), "test2"]) == ("No", "")

        # Broken @test_throws
        # @test_throws KeyError tab[ (1, :key1 ), "test2"]
        # @test_throws KeyError tab[ (1, :key10), "test2"]
        @test_skip tab[ (1, :key1 ), "test2"]
        @test_skip tab[ (1, :key10), "test2"]

        # Check that indexing into the wrong block throws an error
        # @test_throws KeyError tab[ (1, "Fixed Effects"), "test2"]
        @test_skip tab[ (1, "Fixed Effects"), "test2"]

        # Check that indexing into IndexedTables works with standard
        # errors
        @test strip.(tab[(1,:key1 ), "test3"]) == ("0.867" , "(0.749)")
        @test strip.(tab[(1,:key2 ), "test3"]) == ("-0.902", "(0.139)")
        @test strip.(tab[(1,:key3 ), "test3"]) == ("-0.494", "(0.358)")
        @test strip.(tab[(1,:key4 ), "test3"]) == ("-0.903", "(1.361)")
        @test strip.(tab[(1,:key5 ), "test3"]) == ("0.864" , "(0.910)")
        @test strip.(tab[(1,:key6 ), "test3"]) == ("2.212" , "(0.332)")
        @test strip.(tab[(1,:key7 ), "test3"]) == ("0.533" , "(0.501)")
        @test strip.(tab[(1,:key8 ), "test3"]) == ("-0.272", "(0.608)")
        @test strip.(tab[(1,:key9 ), "test3"]) == ("0.502" , "(0.269)")
        @test strip.(tab[(1,:key10), "test3"]) == ("-0.517", "(1.226)")
    end
end
