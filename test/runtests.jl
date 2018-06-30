using   TexTables
import  TexTables:  TableIndex, TableDict
using   DataStructures
using   Base.Test

include("helper.jl")

tests = [   "tablecol", "composite_tables", "indexing", "printing",
            "examples", "quicktools"]

@testset "TexTables" begin
    for testsuite in tests
        @testset "$testsuite" begin
            include("$testsuite.jl")
        end
    end
end
