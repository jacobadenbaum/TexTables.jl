using Tables
using Base.Test

# Baseline check
srand(1234)
x = randn(10)
keys = [Symbol(:key, i) for i=1:10]
t1 = TableCol("test", keys, x)
t2 = TableCol("test2", keys[2:9], x[2:9])
t3 = TableCol("test3", keys, x, randn(10) .|> abs .|> sqrt)
tab= Table(t1, t2, t3)

@test tex(tab) == "\\begin{tabular}{r|ccc}\n\\toprule \n      & test   & test2  & test3   \\\\ \\hline \n key1 & 0.867  &        & 0.867   \\\\ \n      &        &        & (0.749) \\\\ \n key2 & -0.902 & -0.902 & -0.902  \\\\ \n      &        &        & (0.139) \\\\ \n key3 & -0.494 & -0.494 & -0.494  \\\\ \n      &        &        & (0.358) \\\\ \n key4 & -0.903 & -0.903 & -0.903  \\\\ \n      &        &        & (1.361) \\\\ \n key5 & 0.864  & 0.864  & 0.864   \\\\ \n      &        &        & (0.910) \\\\ \n key6 & 2.212  & 2.212  & 2.212   \\\\ \n      &        &        & (0.332) \\\\ \n key7 & 0.533  & 0.533  & 0.533   \\\\ \n      &        &        & (0.501) \\\\ \n key8 & -0.272 & -0.272 & -0.272  \\\\ \n      &        &        & (0.608) \\\\ \n key9 & 0.502  & 0.502  & 0.502   \\\\ \n      &        &        & (0.269) \\\\ \nkey10 & -0.517 &        & -0.517  \\\\ \n      &        &        & (1.226) \\\\ \n\\bottomrule \n\\end{tabular}"


# Composite Table Checks
t4 = TableCol("test" , Dict("Boolean"=>"Yes"))
t5 = TableCol("test2", Dict("Boolean"=>"No"))
t6 = TableCol("test3", Dict("Boolean"=>"Yes"))

# Build the table one way
tab2= Table(t4, t5, t6)
tab3 = CompositeTable([tab; tab2])

# Build it with joins the other way
c1 = CompositeTable([t1; t4])
c2 = CompositeTable([t2; t5])
c3 = CompositeTable([t3; t6])
tab4 = join(c1, c2, c3)

@test tex(tab3) == tex(tab4)


