# Baseline check
using Random

x = [0.8673472019512456, -0.9017438158568171, -0.4944787535042339,
    -0.9029142938652416, 0.8644013132535154, 2.2118774995743475,
    0.5328132821695382, -0.27173539603462066, 0.5023344963886675,
    -0.5169836206932686] 
x2 = [-0.5605013381807765, -0.019291781689849075, 0.12806443451512645,
    1.852782957725545, -0.8277634318169205, 0.11009612632217552,
    -0.2511757400198831, 0.3697140350317453, 0.07211635315125874,
    -1.503429457351051]
y  = [Symbol(:key, i) for i=1:10]
t1 = TableCol("test", y, x)
t2 = TableCol("test2", y[2:9], x[2:9])
t3 = TableCol("test3", y, x, x2 .|> abs .|> sqrt)
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
