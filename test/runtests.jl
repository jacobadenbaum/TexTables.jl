using Tables
using Base.Test

# Baseline check
srand(1234)
x = randn(10)
keys = [Symbol(:key, i) for i=1:10]
c1 = TableCol("test", keys, x)
c2 = TableCol("test2", keys[2:9], x[2:9])
c3 = TableCol("test3", keys, x, randn(10) .|> abs .|> sqrt)
t = Table(c1, c2, c3)

@test tex(t) == "\\begin{tabular}{r|ccc}\n\\toprule \n      & test   & test2  & test3   \\\\ \\hline \n key1 & 0.867  &        & 0.867   \\\\ \n      &        &        & (0.749) \\\\ \n key2 & -0.902 & -0.902 & -0.902  \\\\ \n      &        &        & (0.139) \\\\ \n key3 & -0.494 & -0.494 & -0.494  \\\\ \n      &        &        & (0.358) \\\\ \n key4 & -0.903 & -0.903 & -0.903  \\\\ \n      &        &        & (1.361) \\\\ \n key5 & 0.864  & 0.864  & 0.864   \\\\ \n      &        &        & (0.910) \\\\ \n key6 & 2.212  & 2.212  & 2.212   \\\\ \n      &        &        & (0.332) \\\\ \n key7 & 0.533  & 0.533  & 0.533   \\\\ \n      &        &        & (0.501) \\\\ \n key8 & -0.272 & -0.272 & -0.272  \\\\ \n      &        &        & (0.608) \\\\ \n key9 & 0.502  & 0.502  & 0.502   \\\\ \n      &        &        & (0.269) \\\\ \nkey10 & -0.517 &        & -0.517  \\\\ \n      &        &        & (1.226) \\\\ \n\\bottomrule \n\\end{tabular}"

