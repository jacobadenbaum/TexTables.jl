
import TexTables: TableIndex, tuplefy

function test_constructor(name, x, y)
    pairs = Pair.(x,y)
    col = TableCol(name, x, y)
    @test col isa TableCol{1,1}

    # Check that all the constructors work
    @test begin
        col2 = TableCol(name, OrderedDict(pairs))
        col2 == col
    end

    @test begin
        col3 = TableCol(name, pairs...)
        col3 == col
    end

    # Build in a loop
    @test begin
        col4 = TableCol(name)
        for (key, val) in zip(x,y)
            col4[key] = val
        end
        col4 == col
    end
end

# This version does it with precisions
function test_constructor(name, x, y, p)
    pairs = Pair.(x,tuple.(y,p))

    col = TableCol(name, x, y, p)
    @test col isa TableCol{1,1}

    # Check that all the constructors work
    @test begin
        col2 = TableCol(name, OrderedDict(pairs))
        col2 == col
    end

    @test begin
        col3 = TableCol(name, pairs...)
        col3 == col
    end

    @test begin
        p1  = Pair.(x, y) |> OrderedDict
        p2  = Pair.(x, p) |> OrderedDict
        col4 = TableCol(name, p1, p2)
        col4 == col
    end

    # Build in a loop
    @test begin
        col5 = TableCol(name)
        for (key, val, se) in zip(x,y,p)
            col5[key] = val, se
        end
        col5 == col
    end
end

@testset "Constructing TableCols" begin

    @testset "Integer Values" begin
        # Data
        name = "test"
        x = ["key1", "key2", "key3"]
        y = [1, 2, 3]

        test_constructor(name, x, y)
    end

    @testset "Float Values with Precision" begin
        # Data
        name = "test"
        x = ["key1", "key2", "key3"]
        y = [1.0, 2.0, 3.0]
        p = [.2, .3, .3]

        test_constructor(name, x, y, p)
    end

    @testset "Construct With Mixed Types" begin

        name = "foo"
        x = ["key1", "key2", "key3", "key4"]
        y = [1, 2.2, (3.2, .24), "bar"]

        test_constructor(name, x, y)

    end

end

@testset "TableIndex" begin

    ####################################################################
    ################### Constructing TableIndex ########################
    ####################################################################
    x = TableIndex(1, "test")
    @test x.idx == (1,)
    @test x.name == (:test,)

    x = TableIndex(1, :test)
    @test x.idx == (1,)
    @test x.name == (:test,)

    ####################################################################
    ################### Comparing TableIndex Values for Sorting ########
    ####################################################################

    a = "a test"
    t = "test"
    z = "z test"

    # Sort Lexicographically on the levels
    @test TableIndex((1,1), (a, t)) < TableIndex((2,1), (a, t))
    @test TableIndex((1,1), (z, t)) < TableIndex((2,1), (a, t))
    @test TableIndex((2,1), (a, t)) < TableIndex((2,1), (z, t))
    @test TableIndex((2,1), (a, t)) <= TableIndex((2,1), (a, z))
    @test TableIndex((2,1), (a, t)) <= TableIndex((2,1), (a, t))
    @test TableIndex((2,1), (a, z)) > TableIndex((2,1), (a, a))

end
