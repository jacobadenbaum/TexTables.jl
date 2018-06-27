

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
        @test_skip col2 == col

    end
end
