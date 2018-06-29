
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
