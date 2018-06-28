using   TexTables
import  TexTables:  TableIndex, TableDict
using   DataStructures
using   Base.Test

tests = ["tablecol",
         "composite_tables",
         "indexing"]

@testset "TexTables" begin
    for testsuite in tests
        @testset "$testsuite" begin
            include("$testsuite.jl")
        end
    end
end
