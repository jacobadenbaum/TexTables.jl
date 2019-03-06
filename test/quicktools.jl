import   TexTables: tuplefy

@testset "tuplefy" begin
    vals = [1, 1.0, "1", :1]
    for x in vals
        @test tuplefy(x) == (x,)
    end
    for x in [(val,) for val in vals]
        @test tuplefy(x) == x
    end
    for x in vals, y in vals
        @test tuplefy((x, y)) == (x,y)
    end
end

@testset "summarize" begin
    df = DataFrame(A=[1,2,3],
                   B=[1.0, 2.0, 3.0],
                   C=[true, true, false],
                   D=BitArray([true, true, false]),
                   E=[1, 2, missing],
                   F=[1.0, 2.0, missing],
                   G=["test1", "test2", "test3"])
    t = summarize(df)
    compare_file(34, to_ascii(t))
    compare_file(35, to_tex(t))
end

@testset "twoway tabulate" begin

    # Check a generic one
    Random.seed!(1234)
    iris            = dataset("datasets", "iris")
    iris[:TestVar]  = rand('A':'B', 150)
    t = tabulate(iris, :Species, :TestVar)

    compare_file(36, to_ascii(t))
    compare_file(37, to_tex(t))

end
