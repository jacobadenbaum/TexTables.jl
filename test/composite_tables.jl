# Baseline check
using Random

Random.seed!(1234)
x  = randn(10)
y  = [Symbol(:key, i) for i=1:10]
t1 = TableCol("test", y, x)
t2 = TableCol("test2", y[2:9], x[2:9])
t3 = TableCol("test3", y, x, randn(10) .|> abs .|> sqrt)
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
@test to_ascii(tab) == to_ascii(tab2)

c1 = append_table(t1, t4)
c2 = append_table(t2, t5)
c3 = append_table(t3, t6)

compare_file(1, to_tex(sub_tab1))
