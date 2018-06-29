########################################################################
#################### Helper Functions for Testing ######################
########################################################################

"""
Compares the contents of the file found at `fpath` to `fstring` line by
line, testing for equality.
"""
function compare_file(fpath::String, fstring::String)
    open(fpath) do f
        lines  = readlines(f)
        lines2 = split(fstring, "\n")

        for (l1, l2) in zip(lines, lines2)
            @test l1 == l2
        end
    end
end

"""
Generates the path to test table `i`
"""
function test_table(i)
    return joinpath("resources", "test_table$i.txt")
end

function compare_file(i::Int, fstring::String)
    compare_file(test_table(i), fstring)
end

function export_table(i, fstring::String)
    open(joinpath("test", test_table(i)), "w") do f
        write(f, fstring)
    end
end

function next_test_table()
    files = readdir(joinpath("test", "resources"))
    nums  = map(files) do file
        m = match(r"(?<=(test_table))\d*(?=(.txt))", file).match
        parse(Int, m)
    end
    return maximum(nums) + 1
end

function export_table(fstring::String)
    next_num = next_test_table()
    export_table(next_num, fstring)
    println("Exported to $(test_table(next_num))")
    return next_num
end
