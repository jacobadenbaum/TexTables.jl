var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Introduction-1",
    "page": "Introduction",
    "title": "Introduction",
    "category": "section",
    "text": "The TexTable package provides an easy way for Julia users to quickly build well-formated and publication-ready ASCII and LaTeX tables from a variety of different data structures.  It allows the user to easily build complex tables from small, modular components in an object oriented fashion, as well as providing some methods for easily constructing common tables from regression output.TexTables.jl is designed for building all sorts of statistical tables in a very modular fashion and for quickly displaying them in the REPL or exporting them to LaTeX.  It’s quite extensible, and probably the most important use cases will be for people who want to make their own custom tables, but it has implemented support for some basic regression tables, cross-tabulations, and summary statistics as proof-of-concept."
},

{
    "location": "index.html#Features-1",
    "page": "Introduction",
    "title": "Features",
    "category": "section",
    "text": "Currently TexTables will allow you to:Build multi-indexed tables programatically with a simple to use interface  that allows for row and column groupings.\nPrint them in the REPL as ASCII tables, or export them to LaTeX for easy  inclusionIt also provides constructors and methods toQuickly construct regression tables from estimated models that adhere to the  LinearModel API.\nAdd customized model metadata (such as the type of estimator used, etc...)\nGroup regression columns into subgroups using multicolumn headings\nAdd significance stars to coefficient estimates.\nUse robust standard errors from CovarianceMatrices.jl or other packages.\nConstruct several standard tables that may be useful in exploratory data  analysis\nSummary tables\nGrouped summary tables.\nOne-way frequency tbales."
},

{
    "location": "index.html#Installation-1",
    "page": "Introduction",
    "title": "Installation",
    "category": "section",
    "text": "TexTables is not yet registered, so it can be installed by cloning it from the repository.Pkg.clone(\"https://github.com/jacobadenbaum/TexTables.jl.git\")"
},

{
    "location": "easy_examples.html#",
    "page": "Easy Examples",
    "title": "Easy Examples",
    "category": "page",
    "text": ""
},

{
    "location": "easy_examples.html#Easy-Examples-1",
    "page": "Easy Examples",
    "title": "Easy Examples",
    "category": "section",
    "text": "Here are just a couple examples of tables that TexTables makes extremely easy to produce and export.  These are mostly proof of concept: TexTables provides a backend that makes the code to write these convenience methods extremely compact."
},

{
    "location": "easy_examples.html#Regression-Tables-1",
    "page": "Easy Examples",
    "title": "Regression Tables",
    "category": "section",
    "text": "DocTestSetup = quote\n    # Get the warning out of the way before we start\n    using TexTables, StatsModels, GLM, RDatasets\n    df = dataset(\"datasets\", \"iris\")\nendusing TexTables, StatsModels, GLM, RDatasets\ndf = dataset(\"datasets\", \"attitude\");\nm1 = lm(@formula( Rating ~ 1 + Raises ), df);\nm2 = lm(@formula( Rating ~ 1 + Raises + Learning), df);\nm3 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges), df);\nm4 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges\n                             + Complaints), df);\nm5 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges\n                                    + Complaints + Critical), df);\ntable = regtable(m1, m2, m3, m4, m5)\n\n# output\n\n            |   (1)    |   (2)    |   (3)    |   (4)    |   (5)\n-------------------------------------------------------------------\n(Intercept) |  19.978* |   15.809 |   14.167 |   11.834 |   11.011\n            | (11.688) | (11.084) | (11.519) |  (8.535) | (11.704)\n     Raises | 0.691*** |   0.379* |    0.352 |   -0.026 |   -0.033\n            |  (0.179) |  (0.217) |  (0.224) |  (0.184) |  (0.202)\n   Learning |          |  0.432** |   0.394* |    0.246 |    0.249\n            |          |  (0.193) |  (0.204) |  (0.154) |  (0.160)\n Privileges |          |          |    0.105 |   -0.103 |   -0.104\n            |          |          |  (0.168) |  (0.132) |  (0.135)\n Complaints |          |          |          | 0.691*** | 0.692***\n            |          |          |          |  (0.146) |  (0.149)\n   Critical |          |          |          |          |    0.015\n            |          |          |          |          |  (0.147)\n-------------------------------------------------------------------\n          N |       30 |       30 |       30 |       30 |       30\n      $R^2$ |    0.348 |    0.451 |    0.459 |    0.715 |    0.715"
},

{
    "location": "easy_examples.html#Grouped-Regression-Tables-1",
    "page": "Easy Examples",
    "title": "Grouped Regression Tables",
    "category": "section",
    "text": "We can add a add a hierarchical structure by passing the model objects as pairs of Strings/Symbols and model objects/tuples of model objects:grouped_table = regtable(   \"Group 1\"=>(m1,m2,m3),\n                            \"Group 2\"=>(m4, m5))\n\n# output\n            |            Group 1             |       Group 2\n            |   (1)    |   (2)    |   (3)    |   (4)    |   (5)\n-------------------------------------------------------------------\n(Intercept) |  19.978* |   15.809 |   14.167 |   11.834 |   11.011\n            | (11.688) | (11.084) | (11.519) |  (8.535) | (11.704)\n     Raises | 0.691*** |   0.379* |    0.352 |   -0.026 |   -0.033\n            |  (0.179) |  (0.217) |  (0.224) |  (0.184) |  (0.202)\n   Learning |          |  0.432** |   0.394* |    0.246 |    0.249\n            |          |  (0.193) |  (0.204) |  (0.154) |  (0.160)\n Privileges |          |          |    0.105 |   -0.103 |   -0.104\n            |          |          |  (0.168) |  (0.132) |  (0.135)\n Complaints |          |          |          | 0.691*** | 0.692***\n            |          |          |          |  (0.146) |  (0.149)\n   Critical |          |          |          |          |    0.015\n            |          |          |          |          |  (0.147)\n-------------------------------------------------------------------\n          N |       30 |       30 |       30 |       30 |       30\n      $R^2$ |    0.348 |    0.451 |    0.459 |    0.715 |    0.715\n"
},

{
    "location": "easy_examples.html#Exporting-to-Latex-1",
    "page": "Easy Examples",
    "title": "Exporting to Latex",
    "category": "section",
    "text": "All of these commands return subtypes of the abstract TexTable type.  Any TexTable can be printed as either an ascii table (as shown above) with the method to_ascii or as a latex table with the method to_tex:to_tex(grouped_table) |> print\n\n# output\n\n\\begin{tabular}{r|ccc|cc}\n\\toprule\n            & \\multicolumn{3}{c}{Group 1}    & \\multicolumn{2}{c}{Group 2} \\\\\n            & (1)      & (2)      & (3)      & (4)          & (5)          \\\\ \\hline\n(Intercept) &  19.978* &   15.809 &   14.167 &       11.834 &       11.011 \\\\\n            & (11.688) & (11.084) & (11.519) &      (8.535) &     (11.704) \\\\\n     Raises & 0.691*** &   0.379* &    0.352 &       -0.026 &       -0.033 \\\\\n            &  (0.179) &  (0.217) &  (0.224) &      (0.184) &      (0.202) \\\\\n   Learning &          &  0.432** &   0.394* &        0.246 &        0.249 \\\\\n            &          &  (0.193) &  (0.204) &      (0.154) &      (0.160) \\\\\n Privileges &          &          &    0.105 &       -0.103 &       -0.104 \\\\\n            &          &          &  (0.168) &      (0.132) &      (0.135) \\\\\n Complaints &          &          &          &     0.691*** &     0.692*** \\\\\n            &          &          &          &      (0.146) &      (0.149) \\\\\n   Critical &          &          &          &              &        0.015 \\\\\n            &          &          &          &              &      (0.147) \\\\ \\hline\n          N &       30 &       30 &       30 &           30 &           30 \\\\\n      $R^2$ &    0.348 &    0.451 &    0.459 &        0.715 &        0.715 \\\\\n\\bottomrule\n\\end{tabular}It\'s as simple as that.  As you can see, higher level groupings will be separated with vertical bars, and their headings will be printed as \\multicolumn environments.  In tables with row-groupings, TexTables will automatically use \\multirow environments.  TableTex will automatically handle printing it in a way that is well aligned and can be read even from the raw tex file, and will align the multi-columns and multi-indexes for you.You can write the table to a tex file yourself, or you can use the convenience wrapper write_tex(fpath::String, t::TexTable)."
},

{
    "location": "easy_examples.html#Summary-Tables-1",
    "page": "Easy Examples",
    "title": "Summary Tables",
    "category": "section",
    "text": "Making summary tables is similarly easy:df = dataset(\"datasets\", \"iris\");\nsummarize(df)\n\n# output\n            | Obs | Mean  | Std. Dev. |  Min  |  Max\n------------------------------------------------------\nSepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900\n SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400\nPetalLength | 150 | 3.758 |     1.765 | 1.000 | 6.900\n PetalWidth | 150 | 1.199 |     0.762 | 0.100 | 2.500\n    Species |     |       |           |       |To choose only a subset of variables, and get a more detailed summary table:summarize(df, [:SepalLength, :SepalWidth], detail=true)\n\n# output\n            | Obs | Mean  | Std. Dev. |  Min  |  p10  |  p25  |  p50  |  p75  |  p90  |  Max\n----------------------------------------------------------------------------------------------\nSepalLength | 150 | 5.843 |     0.828 | 4.300 | 4.800 | 5.100 | 5.800 | 6.400 | 6.900 | 7.900\n SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 2.500 | 2.800 | 3.000 | 3.300 | 3.610 | 4.400To group by another variable in the DataFrame, use the summarize_by function:c1 = summarize_by(df, :Species, [:SepalLength, :SepalWidth])\n\n# output\n\n           |             | Obs | Mean  | Std. Dev. |  Min  |  Max\n-------------------------------------------------------------------\n    setosa | SepalLength |  50 | 5.006 |     0.352 | 4.300 | 5.800\n           |  SepalWidth |  50 | 3.428 |     0.379 | 2.300 | 4.400\n-------------------------------------------------------------------\nversicolor | SepalLength |  50 | 5.936 |     0.516 | 4.900 | 7.000\n           |  SepalWidth |  50 | 2.770 |     0.314 | 2.000 | 3.400\n-------------------------------------------------------------------\n virginica | SepalLength |  50 | 6.588 |     0.636 | 4.900 | 7.900\n           |  SepalWidth |  50 | 2.974 |     0.322 | 2.200 | 3.800"
},

{
    "location": "basic_usage.html#",
    "page": "Basic Usage",
    "title": "Basic Usage",
    "category": "page",
    "text": ""
},

{
    "location": "basic_usage.html#Basic-Usage-1",
    "page": "Basic Usage",
    "title": "Basic Usage",
    "category": "section",
    "text": "The goal for this package is to make most tables extremely easy to assemble on the fly.  In the next few sections, I\'ll demonstrate some of the basic usage, primarily using several convenience functions that make it easy to construct common tables.  However, these functions are a small subset of what TexTables is designed for: it should be easy to programatically make any type of hierarchical table and and print it to LaTeX.  For more details on how to easily roll-your-own tables (or integrate LaTeX tabular output into your own package) using TexTables, see the Advanced Usage section below."
},

{
    "location": "basic_usage.html#Making-A-Table-of-Summary-Statistics-1",
    "page": "Basic Usage",
    "title": "Making A Table of Summary Statistics",
    "category": "section",
    "text": "Let\'s download the iris dataset from RDatasets, and quickly compute some summary statistics.julia> using RDatasets, TexTables, DataStructures, DataFrames\n\njulia> df = dataset(\"datasets\", \"iris\");\n\njulia> summarize(df)\n            | Obs | Mean  | Std. Dev. |  Min  |  Max\n------------------------------------------------------\nSepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900\n SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400\nPetalLength | 150 | 3.758 |     1.765 | 1.000 | 6.900\n PetalWidth | 150 | 1.199 |     0.762 | 0.100 | 2.500\n    Species |     |       |           |       |If we want more detail, we can pass the detail=true keyword argument:julia> summarize(df,detail=true)\n            | Obs | Mean  | Std. Dev. |  Min  |  p10  |  p25  |  p50  |  p75  |  p90  |  Max\n----------------------------------------------------------------------------------------------\nSepalLength | 150 | 5.843 |     0.828 | 4.300 | 4.800 | 5.100 | 5.800 | 6.400 | 6.900 | 7.900\n SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 2.500 | 2.800 | 3.000 | 3.300 | 3.610 | 4.400\nPetalLength | 150 | 3.758 |     1.765 | 1.000 | 1.400 | 1.600 | 4.350 | 5.100 | 5.800 | 6.900\n PetalWidth | 150 | 1.199 |     0.762 | 0.100 | 0.200 | 0.300 | 1.300 | 1.800 | 2.200 | 2.500\n    Species |     |       |           |       |       |       |       |       |       |\nWe can restrict to only some variables by passing a second positional argument, which can be either a Symbol or an iterable collection of symbols.The summarize function is similar to the Stata command summarize: it reports string variables all entries missing, and skips all missing values when computing statistics.To customize what statistics are calculated, you can pass summarize a stats::Tuple{Union{Symbol,String},Function} (or just a single pair will work too) keyword argument:# Quantiles of nonmissing values (need to collect to pass to quantile)\n\njulia> nomiss(x) = skipmissing(x) |> collect;\n\njulia> new_stats = (\"p25\" => x-> quantile(nomiss(x), .25),\n                    \"p50\" => x-> quantile(nomiss(x), .5),\n                    \"p75\" => x-> quantile(nomiss(x), .75));\n\njulia> summarize(df, stats=new_stats)\n            |  p25  |  p50  |  p75\n------------------------------------\nSepalLength | 5.100 | 5.800 | 6.400\n SepalWidth | 2.800 | 3.000 | 3.300\nPetalLength | 1.600 | 4.350 | 5.100\n PetalWidth | 0.300 | 1.300 | 1.800\n    Species |       |       |"
},

{
    "location": "basic_usage.html#Stacking-Tables-1",
    "page": "Basic Usage",
    "title": "Stacking Tables",
    "category": "section",
    "text": "It\'s easy to stack two tables that you created at different parts of your code using calls to hcat or vcat:julia> t11 = summarize(df, :SepalLength)\n            | Obs | Mean  | Std. Dev. |  Min  |  Max\n------------------------------------------------------\nSepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900\n\njulia> t21= summarize(df, :SepalWidth)\n           | Obs | Mean  | Std. Dev. |  Min  |  Max\n-----------------------------------------------------\nSepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400\n\njulia> t12 = summarize(df, :SepalLength, stats=new_stats)\n            |  p25  |  p50  |  p75\n------------------------------------\nSepalLength | 5.100 | 5.800 | 6.400\n\njulia> t22 = summarize(df, :SepalWidth, stats=new_stats)\n           |  p25  |  p50  |  p75\n-----------------------------------\nSepalWidth | 2.800 | 3.000 | 3.300\n\njulia> tab = [t11   t12\n              t21   t22]\n            | Obs | Mean  | Std. Dev. |  Min  |  Max  |  p25  |  p50  |  p75\n------------------------------------------------------------------------------\nSepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900 | 5.100 | 5.800 | 6.400\n SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400 | 2.800 | 3.000 | 3.300You can also group statistics together with a call to the function join_table.  This constructs a new table with a column multi-index that groups your data into two column blocks.julia> join_table( \"Regular Summarize\"  =>vcat(t11, t21),\n                    \"My Detail\"         =>vcat(t12, t22))\n            |            Regular Summarize            |       My Detail\n            | Obs | Mean  | Std. Dev. |  Min  |  Max  |  p25  |  p50  |  p75\n------------------------------------------------------------------------------\nSepalLength | 150 | 5.843 |     0.828 | 4.300 | 7.900 | 5.100 | 5.800 | 6.400\n SepalWidth | 150 | 3.057 |     0.436 | 2.000 | 4.400 | 2.800 | 3.000 | 3.300\nThere is an analagous function for creating multi-indexed row tables append_table.  You can see it in action with a call to the function summarize_by, which calculates summary statistics by grouping on a variable.julia> c1 = summarize_by(df, :Species, [:SepalLength, :SepalWidth])\n           |             | Obs | Mean  | Std. Dev. |  Min  |  Max\n-------------------------------------------------------------------\n    setosa | SepalLength |  50 | 5.006 |     0.352 | 4.300 | 5.800\n           |  SepalWidth |  50 | 3.428 |     0.379 | 2.300 | 4.400\n-------------------------------------------------------------------\nversicolor | SepalLength |  50 | 5.936 |     0.516 | 4.900 | 7.000\n           |  SepalWidth |  50 | 2.770 |     0.314 | 2.000 | 3.400\n-------------------------------------------------------------------\n virginica | SepalLength |  50 | 6.588 |     0.636 | 4.900 | 7.900\n           |  SepalWidth |  50 | 2.974 |     0.322 | 2.200 | 3.800\n\njulia> c2 = summarize_by(df, :Species, [:SepalLength, :SepalWidth],\n                         stats=new_stats)\n           |             |  p25  |  p50  |  p75\n-------------------------------------------------\n    setosa | SepalLength | 4.800 | 5.000 | 5.200\n           |  SepalWidth | 3.200 | 3.400 | 3.675\n-------------------------------------------------\nversicolor | SepalLength | 5.600 | 5.900 | 6.300\n           |  SepalWidth | 2.525 | 2.800 | 3.000\n-------------------------------------------------\n virginica | SepalLength | 6.225 | 6.500 | 6.900\n           |  SepalWidth | 2.800 | 3.000 | 3.175Now, when we horizontally concatenate c1 and c2, they will automatically maintiain the block-ordering in the rows:julia> final_table = join_table(\"Regular Summarize\"=>c1, \"My Detail\"=>c2)\n           |             |            Regular Summarize            |       My Detail\n           |             | Obs | Mean  | Std. Dev. |  Min  |  Max  |  p25  |  p50  |  p75\n-------------------------------------------------------------------------------------------\n    setosa | SepalLength |  50 | 5.006 |     0.352 | 4.300 | 5.800 | 4.800 | 5.000 | 5.200\n           |  SepalWidth |  50 | 3.428 |     0.379 | 2.300 | 4.400 | 3.200 | 3.400 | 3.675\n-------------------------------------------------------------------------------------------\nversicolor | SepalLength |  50 | 5.936 |     0.516 | 4.900 | 7.000 | 5.600 | 5.900 | 6.300\n           |  SepalWidth |  50 | 2.770 |     0.314 | 2.000 | 3.400 | 2.525 | 2.800 | 3.000\n-------------------------------------------------------------------------------------------\n virginica | SepalLength |  50 | 6.588 |     0.636 | 4.900 | 7.900 | 6.225 | 6.500 | 6.900\n           |  SepalWidth |  50 | 2.974 |     0.322 | 2.200 | 3.800 | 2.800 | 3.000 | 3.175"
},

{
    "location": "basic_usage.html#Tabulate-Function-1",
    "page": "Basic Usage",
    "title": "Tabulate Function",
    "category": "section",
    "text": "TexTables also provides a convenience tabulate function:julia> tabulate(df, :Species)\n           | Freq. | Percent |  Cum.\n---------------------------------------\n    setosa |    50 |  33.333 |  33.333\nversicolor |    50 |  33.333 |  66.667\n virginica |    50 |  33.333 | 100.000\n---------------------------------------\n     Total |   150 | 100.000 |In the future, I may add support for two way tables (it\'s a very easy extension)."
},

{
    "location": "basic_usage.html#StatsModels-Integrations-1",
    "page": "Basic Usage",
    "title": "StatsModels Integrations",
    "category": "section",
    "text": "Let\'s say that we want to run a few regressions on some data that we happened to come by:using StatsModels, GLM\ndf = dataset(\"datasets\", \"attitude\")\nm1 = lm(@formula( Rating ~ 1 + Raises ), df)\nm2 = lm(@formula( Rating ~ 1 + Raises + Learning), df)\nm3 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges), df)\nm4 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges\n                             + Complaints), df)\nm5 = lm(@formula( Rating ~ 1 + Raises + Learning + Privileges\n                             + Complaints + Critical), df)We can construct a single column for any one of these with the TableCol constructor:julia> t1 = TableCol(\"(1)\", m1)\n            |   (1)\n-----------------------\n(Intercept) |  19.978*\n            | (11.688)\n     Raises | 0.691***\n            |  (0.179)\n-----------------------\n          N |       30\n      $R^2$ |    0.348But in general, it is easier to just use the regtable function when combining several different models:julia> reg_table = regtable(m1, m2, m3, m4, m5)\n            |   (1)    |   (2)    |   (3)    |   (4)    |   (5)\n-------------------------------------------------------------------\n(Intercept) |  19.978* |   15.809 |   14.167 |   11.834 |   11.011\n            | (11.688) | (11.084) | (11.519) |  (8.535) | (11.704)\n     Raises | 0.691*** |   0.379* |    0.352 |   -0.026 |   -0.033\n            |  (0.179) |  (0.217) |  (0.224) |  (0.184) |  (0.202)\n   Learning |          |  0.432** |   0.394* |    0.246 |    0.249\n            |          |  (0.193) |  (0.204) |  (0.154) |  (0.160)\n Privileges |          |          |    0.105 |   -0.103 |   -0.104\n            |          |          |  (0.168) |  (0.132) |  (0.135)\n Complaints |          |          |          | 0.691*** | 0.692***\n            |          |          |          |  (0.146) |  (0.149)\n   Critical |          |          |          |          |    0.015\n            |          |          |          |          |  (0.147)\n-------------------------------------------------------------------\n          N |       30 |       30 |       30 |       30 |       30\n      $R^2$ |    0.348 |    0.451 |    0.459 |    0.715 |    0.715Currently, TexTables works with several standard regression packages in the StatsModels family to construct custom coefficient tables. I\'ve mostly implemented these as proof of concept, since I\'m not sure how best to proceed on extending it to more model types.  By default, TexTables will display significance stars using p-value thresholds of 0.1 for 1 star, 0.05 for 2 stars, and 0.01 for 3 stars (as is standard).I think that I may spin these off into a \"formulas\" package at some point in the future.If you are interested in integrating TexTables into your regression package, please see the topic below under \"Advanced Usage.\""
},

{
    "location": "basic_usage.html#Row-and-Column-Blocks-1",
    "page": "Basic Usage",
    "title": "Row and Column Blocks",
    "category": "section",
    "text": "As you can see, the summary statistics are kept in a separate row-block while the columns are being merged together. We can do this either with unnamed groups (like in the previous example), or with named groups that will be visible in the table itself.Suppose that our first 3 regressions needed to be visually grouped together under a single heading, and the last two were separate.  We could instead construct each group separately and then combine them together with the join_table function:group1 = regtable(m1, m2, m3)\ngroup2 = regtable(m4, m5)\ngrouped_table = join_table( \"Group 1\"=>group1,\n                            \"Group 2\"=>group2)This will display as:julia> grouped_table = join_table( \"Group 1\"=>group1,\n                                   \"Group 2\"=>group2)\n            |            Group 1             |      Group 2\n            |   (1)    |   (2)    |   (3)    |   (1)   |   (2)\n------------------------------------------------------------------\n(Intercept) |   19.978 |   15.809 |   14.167 |  11.834 |   11.011\n            | (11.688) | (11.084) | (11.519) | (8.535) | (11.704)\n     Raises |    0.691 |    0.379 |    0.352 |  -0.026 |   -0.033\n            |  (0.179) |  (0.217) |  (0.224) | (0.184) |  (0.202)\n   Learning |          |    0.432 |    0.394 |   0.246 |    0.249\n            |          |  (0.193) |  (0.204) | (0.154) |  (0.160)\n Privileges |          |          |    0.105 |  -0.103 |   -0.104\n            |          |          |  (0.168) | (0.132) |  (0.135)\n Complaints |          |          |          |   0.691 |    0.692\n            |          |          |          | (0.146) |  (0.149)\n   Critical |          |          |          |         |    0.015\n            |          |          |          |         |  (0.147)\n------------------------------------------------------------------\n          N |       30 |       30 |       30 |      30 |       30\n      $R^2$ |    0.348 |    0.451 |    0.459 |   0.715 |    0.715If instead, we wanted to maintain a consistent numbering from (1)-(5), we could do it using the regtable function:julia> regtable(\"Group 1\"=>(m1, m2, m3), \"Group 2\"=>(m4, m5))\n            |            Group 1             |       Group 2\n            |   (1)    |   (2)    |   (3)    |   (4)    |   (5)\n-------------------------------------------------------------------\n(Intercept) |  19.978* |   15.809 |   14.167 |   11.834 |   11.011\n            | (11.688) | (11.084) | (11.519) |  (8.535) | (11.704)\n     Raises | 0.691*** |   0.379* |    0.352 |   -0.026 |   -0.033\n            |  (0.179) |  (0.217) |  (0.224) |  (0.184) |  (0.202)\n   Learning |          |  0.432** |   0.394* |    0.246 |    0.249\n            |          |  (0.193) |  (0.204) |  (0.154) |  (0.160)\n Privileges |          |          |    0.105 |   -0.103 |   -0.104\n            |          |          |  (0.168) |  (0.132) |  (0.135)\n Complaints |          |          |          | 0.691*** | 0.692***\n            |          |          |          |  (0.146) |  (0.149)\n   Critical |          |          |          |          |    0.015\n            |          |          |          |          |  (0.147)\n-------------------------------------------------------------------\n          N |       30 |       30 |       30 |       30 |       30\n      $R^2$ |    0.348 |    0.451 |    0.459 |    0.715 |    0.715And in latex, the group labels will be displayed with \\multicolumn commands:\\begin{tabular}{r|ccc|cc}\n\\toprule\n            & \\multicolumn{3}{c}{Group 1}    & \\multicolumn{2}{c}{Group 2}\\\\\n            & (1)      & (2)      & (3)      & (4)         & (5)          \\\\ \\hline\n(Intercept) &   19.978 &   15.809 &   14.167 &      11.834 &       11.011 \\\\\n            & (11.688) & (11.084) & (11.519) &     (8.535) &     (11.704) \\\\\n     Raises &    0.691 &    0.379 &    0.352 &      -0.026 &       -0.033 \\\\\n            &  (0.179) &  (0.217) &  (0.224) &     (0.184) &      (0.202) \\\\\n   Learning &          &    0.432 &    0.394 &       0.246 &        0.249 \\\\\n            &          &  (0.193) &  (0.204) &     (0.154) &      (0.160) \\\\\n Privileges &          &          &    0.105 &      -0.103 &       -0.104 \\\\\n            &          &          &  (0.168) &     (0.132) &      (0.135) \\\\\n Complaints &          &          &          &       0.691 &        0.692 \\\\\n            &          &          &          &     (0.146) &      (0.149) \\\\\n   Critical &          &          &          &             &        0.015 \\\\\n            &          &          &          &             &      (0.147) \\\\ \\hline\n          N &       30 &       30 &       30 &          30 &           30 \\\\\n      $R^2$ &    0.348 &    0.451 &    0.459 &       0.715 &        0.715 \\\\\n\\bottomrule\n\\end{tabular}The vertical analogue of join_table is the function append_table. Both will also accept the table objects as arguments instead of pairs if you want to construct the row/column groups without adding a visible multi-index."
},

{
    "location": "basic_usage.html#Display-Options-1",
    "page": "Basic Usage",
    "title": "Display Options",
    "category": "section",
    "text": "You can recover the string output using the functions to_latex and to_ascii.  But, it is also possible to tweak the layout of the tables by passing keyword arguments to the print, show, to_tex, or to_ascii functions.  For instance, if you would like to display your standard errors on the same row as the coefficients, you can do so with the se_pos argument:julia> print(to_ascii(hcat( TableCol(\"(1)\", m1), TableCol(\"(2)\", m2)),\n                      se_pos=:inline))\n            |       (1)        |       (2)\n-------------------------------------------------\n(Intercept) | 19.978* (11.688) | 15.809 (11.084)\n     Raises | 0.691*** (0.179) |  0.379* (0.217)\n   Learning |                  | 0.432** (0.193)\n-------------------------------------------------\n          N |               30 |              30\n      $R^2$ |            0.348 |           0.451Similarly, if you want to print a table without showing the significance stars, then simply pass the keyword argument star=false:julia> print(to_ascii(hcat( TableCol(\"(1)\", m1), TableCol(\"(2)\", m2)),\n                      star=false))\n            |   (1)    |   (2)\n----------------------------------\n(Intercept) |   19.978 |   15.809\n            | (11.688) | (11.084)\n     Raises |    0.691 |    0.379\n            |  (0.179) |  (0.217)\n   Learning |          |    0.432\n            |          |  (0.193)\n----------------------------------\n          N |       30 |       30\n      $R^2$ |    0.348 |    0.451\nCurrently, TexTables supports the following display options:pad::Int (default 1)      The number of spaces to pad the separator characters on each side.\nse_pos::Symbol (default :below)\n:below – Prints standard errors in parentheses on a second line  below the coefficients\n:inline – Prints standard errors in parentheses on the same  line as the coefficients\n:none – Supresses standard errors.  (I don\'t know why you would  want to do this... you probably shouldn\'t ever use it.)\nstar::Bool (default true)      If true, then prints any table entries that have been decorated      with significance stars with the appropriate number of stars."
},

{
    "location": "basic_usage.html#Changing-the-Default-Formatting-1",
    "page": "Basic Usage",
    "title": "Changing the Default Formatting",
    "category": "section",
    "text": "TexTables stores all of the table entries using special formatting aware container types types that are subtypes of the abstract type FormattedNumber.  By default, TexTables displays floating points with three decimal precision (and auto-converts to scientific notation for values less than 1e-3 and greater than 1e5).  Formatting is done using Python-like formatting strings (Implemented by the excellent Formatting.jl package) If you would like to change the default formatting values, you can do so using the macro @fmt:@fmt Real = \"{:.3f}\"        # Sets the default for reals to .3 fixed precision\n@fmt Real = \"{:.2f}\"        # Sets the default for reals to .2 fixed precision\n@fmt Real = \"{:.2e}\"        # Sets the default for reals to .2 scientific\n@fmt Int  = \"{:,n}\"         # Sets the default for integers to use commas\n@fmt Bool = \"{:}\"           # No extra formatting for Bools\n@fmt AbstractString= \"{:}\"  # No extra formatting for StringsNote that this controls the _defaults_ used when constructing a FormattedNumber.  If you want to change the formatting in a table that has already been constructed, you need to manually change the format field of each entry in the table:julia> x = FormattedNumber(5.0)\n5.000\n\njulia> x.format\n\"{:.3f\"}\n\njulia> x.format = \"{:.3e}\";\njulia> x\n5.000e+00"
},

{
    "location": "regression_tables.html#",
    "page": "Regression API",
    "title": "Regression API",
    "category": "page",
    "text": ""
},

{
    "location": "regression_tables.html#Regression-Tables-API-1",
    "page": "Regression API",
    "title": "Regression Tables API",
    "category": "section",
    "text": "TexTables should be able to provide a basic regression table for any model that adheres to the RegressionModel API found in StatsBase and makes it easy to customize the tables with additional fit statistics or model information as you see fit.  This section documents how to use and customize the regression tables functionality for models in your code, as well as how to override the default settings for a model in your Package."
},

{
    "location": "regression_tables.html#Special-Structure-of-Regression-Tables-1",
    "page": "Regression API",
    "title": "Special Structure of Regression Tables",
    "category": "section",
    "text": "Regression tables in TexTables are constructed using a special API that is provided to ensure that the regression tables from different estimators (potentially from separate packages) can be merged together.  You should _not_ construct your tables directly if you want them to merge nicely with the standard regression tables.  Instead, you should use the methods documented in this section.Regression tables are divided into 3 separate row blocks:Coefficients: This block contains the parameter estimates and  standard errors (possibly decorated with stars for p-values) and always  appears first\nMetadata: This block is empty by default (and therefore will not be  printed in the table), but can be populated by the user to include  column/model specific metadata.  For example, a user might want to denote  whether or not they controlled for one of the variables in their data, or  which estimator they used in each column (OLS/Fixed Effects/2SLS/etc...)\nFit Statistics: This block contains fit statistics.  It defaults to R^2  and the number of observations, but this can be changed by the user.You can construct sub-blocks within each of these three layers, although this is turned off by default.  In order to support these three layers and the possible addition of sublayers, TableCols that conform to this API must be subtypes of TableCol{3,M} where M.  For convenience a typealias RegCol{M} = TableCol{3,M} is provided, along with a constructor for empty RegCols from just the desired header."
},

{
    "location": "regression_tables.html#Adding-Each-Block-1",
    "page": "Regression API",
    "title": "Adding Each Block",
    "category": "section",
    "text": "You can construct or add to each of the three blocks using the convenience methods setcoef!, setmeta!, and setstats!.  All three have an identical syntax:set[block]!(t::RegCol, key, val[, se]; level=1, name=\"\")\nset[block]!(t::RegCol, key=>val; level=1, name=\"\")\nset[block]!(t::RegCol, kv::Associative)This will insert into t a key/value pair (possibly with a standard error) within the specified  block.  Like the TableCol constructor, the pairs can be passed as either individual key/value[/se] tuples or pairs, as several vectors of key/value[/se] pairs, or as an associative.To add additional sub-blocks, use the level keyword argument.  Integers less than 0 will appears in blocks above the standard block, and integers greater than 1 will appear below it.To name the block or sub-block, pass a nonempty string as the name keyword argument.For instance, if you wanted to construct a regression column with two coefficients 1.32 (0.89) and -0.21 (0.01), metadata that indicates that the underlying estimation rotuine used OLS, and an R^2 of 0.73, then you would run the following code:col = RegCol(\"My Column\")\nsetcoef!(col, \"Coef 1\"=>(1.32, 0.89), \"Coef 2\"=>(-0.21, 0.01))\nsetmeta!(col, :Estimator=>\"OLS\")\nsetstats!(col, \"\\$R^2\\$\"=>0.73)\nprintln(col)\n\n# output\n          | My Column\n----------------------\n   Coef 1 |     1.320\n          |   (0.890)\n   Coef 2 |    -0.210\n          |   (0.010)\n----------------------\nEstimator |       OLS\n----------------------\n    $R^2$ |     0.730"
},

{
    "location": "regression_tables.html#Robust-Standard-Errors-1",
    "page": "Regression API",
    "title": "Robust Standard Errors",
    "category": "section",
    "text": "If you would like to overide the standard stderror function for your table, use the stderror keyword argument.  For instance, you might want to use the CovarianceMatrices package to compute robust standard errors.  In this case, you would simply define a new functionusing CovarianceMatrices\nrobust(m) = stderror(m, HC0)\nTableCol(\"My Column\", m; stderror=robust)Note: This feature is relatively experimental and its usage may change in future releases."
},

{
    "location": "regression_tables.html#Integrating-TexTables-into-your-own-Estimation-Package-1",
    "page": "Regression API",
    "title": "Integrating TexTables into your own Estimation Package",
    "category": "section",
    "text": "Once you know how you would like your model\'s regression tables to look, it is extremely easy to built it with TexTables.  For instance, the code to integrate TexTables with some of the basic StatsModels.jl RegressionModel types is extremely short, and quite instructive to examine:function TableCol(header, m::RegressionModel;\n                  stats=(:N=>Int∘nobs, \"\\$R^2\\$\"=>r2),\n                  meta=(), stderror::Function=stderror, kwargs...)\n\n    # Compute p-values\n    pval(m) = ccdf.(FDist(1, dof_residual(m)),\n                    abs2.(coef(m)./stderror(m)))\n\n    # Initialize the column\n    col  = RegCol(header)\n\n    # Add the coefficients\n    for (name, val, se, p) in zip(coefnames(m), coef(m), stderror(m), pval(m))\n        addcoef!(col, name, val, se)\n        0.05 <  p <= .1  && star!(col[name], 1)\n        0.01 <  p <= .05 && star!(col[name], 2)\n                p <= .01 && star!(col[name], 3)\n    end\n\n    # Add in the fit statistics\n    addstats!(col, OrderedDict(p.first=>p.second(m) for p in stats))\n\n    # Add in the metadata\n    addmeta!(col, OrderedDict(p.first=>p.second(m) for p in meta))\n\n    return col\nendHere, weConstructed an empty column with the header value passed by the user\nLooped through the coefficients, their names, their standard errors, and their pvalues.  On each iteration, we:\na.  Insert the coefficient value and its standard error into the table\nb.  Check whether the p-values fall below the desired threshold (in     descending order), and if so, call the function     star!(x::FormattedNumber, num_stars) with the desired number of     stars.TexTables stores all of the table values internally with a FormattedNumber type, which contains the value, the standard error if appropriate, the number of stars the value should display, and a formatting string.  As a result, it is probably easiest to set the table value first, and then add stars later with the star! function. However, we could also have constructed each value directly as:if .05 < pval <= .1\n    coef_block[name] = val, se, 1\nelseif 0.01 < pval <= .05\n    coef_block[name] = val, se, 2\nelseif pval <= .01\n    coef_block[name] = val, se, 3\nendHow you choose to do it is mostly a matter of taste and coding style. Note that by default, the number of stars is always set to zero.  In other words, TexTables will _not_ assume that it can infer the number of significance stars from the standard errors and the coefficients alone.  If you want to annotate your table with significance stars, you must explicitly choose in your model-specific code which entries to annotate and how many stars they should have."
},

{
    "location": "advanced_usage.html#",
    "page": "Advanced Usage",
    "title": "Advanced Usage",
    "category": "page",
    "text": ""
},

{
    "location": "advanced_usage.html#Advanced-Usage-1",
    "page": "Advanced Usage",
    "title": "Advanced Usage",
    "category": "section",
    "text": "These sections are for advanced users who are interested in fine-tuning their own custom tables or integrating TexTables into their packages."
},

{
    "location": "advanced_usage.html#Building-Tables-from-Scratch-1",
    "page": "Advanced Usage",
    "title": "Building Tables from Scratch",
    "category": "section",
    "text": "The core object when constructing tables with TexTables is the TableCol type.  This is just a wrapper around an OrderedDict and a header index, that enforces conversion of the header and the keys to a special multi-index type that work with the TexTables structure for printing.Let\'s make up some data (values, keys, and standard errors) so that we can see all of the different ways to construct columns:julia> srand(1234);\n\njulia> vals  = randn(10)\n10-element Array{Float64,1}:\n  0.867347\n -0.901744\n -0.494479\n -0.902914\n  0.864401\n  2.21188\n  0.532813\n -0.271735\n  0.502334\n -0.516984\n\njulia> key  = [Symbol(:key, i) for i=1:10];\n\njulia> se  = randn(10) .|> abs .|> sqrt\n10-element Array{Float64,1}:\n 0.748666\n 0.138895\n 0.357861\n 1.36117\n 0.909815\n 0.331807\n 0.501174\n 0.608041\n 0.268545\n 1.22614"
},

{
    "location": "advanced_usage.html#Constructing-Columns-From-Vectors:-1",
    "page": "Advanced Usage",
    "title": "Constructing Columns From Vectors:",
    "category": "section",
    "text": "If your data is already in vector form, the easiest way to construct a TableCol is to just pass the vectors as positional arguments:julia> t1 = TableCol(\"Column\", key, vals)\n      | Column\n---------------\n key1 |  0.867\n key2 | -0.902\n key3 | -0.494\n key4 | -0.903\n key5 |  0.864\n key6 |  2.212\n key7 |  0.533\n key8 | -0.272\n key9 |  0.502\nkey10 | -0.517\n\njulia> typeof(t1)\nTexTables.TableCol{1,1}We can also build it iteratively by constructing an empty TableCol object and populating it in a loop:julia>  t2 = TableCol(\"Column\")\nIndexedTable{1,1} of size (0, 1)\n\njulia>  for (k, v) in zip(key, vals)\n            t2[k] = v\n        end\n\njulia> t2 == t1\ntrue"
},

{
    "location": "advanced_usage.html#Constructing-Columns-with-Standard-Errors-1",
    "page": "Advanced Usage",
    "title": "Constructing Columns with Standard Errors",
    "category": "section",
    "text": "To include standard errors, we can either pass the column of standard errors as a third column, or we can set the index using tuples of (key, value) pairsjulia>  t3 = TableCol(\"Column 2\");\n\njulia>  for (k, v, p) in zip(key, vals, se)\n            t3[k] = v, p\n        end\n\njulia> t3\n      | Column 2\n-----------------\n key1 |    0.867\n      |  (0.749)\n key2 |   -0.902\n      |  (0.139)\n key3 |   -0.494\n      |  (0.358)\n key4 |   -0.903\n      |  (1.361)\n key5 |    0.864\n      |  (0.910)\n key6 |    2.212\n      |  (0.332)\n key7 |    0.533\n      |  (0.501)\n key8 |   -0.272\n      |  (0.608)\n key9 |    0.502\n      |  (0.269)\nkey10 |   -0.517\n      |  (1.226)\n\njulia> t3 == TableCol(\"Column 2\", key,vals, se)\ntrue"
},

{
    "location": "advanced_usage.html#Constructing-Columns-from-:-Associative-1",
    "page": "Advanced Usage",
    "title": "Constructing Columns from <: Associative",
    "category": "section",
    "text": "You can also pass an Associative of key=>value pairs like a Dict or an OrderedDict.  Beware though of using Dict types to pass the data, since they will not maintain insertion order:julia> dict  = Dict(Pair.(key, vals));\njulia> dict2 = OrderedDict(Pair.(key, vals));\njulia> TableCol(\"Column\", dict) == TableCol(\"Column\",dict2)\nfalseTo pass standard errors in an Associative as well, you can either pass an associative where the values are tuples, or you can pass two different lookup tables:julia> se_dict1= OrderedDict(Pair.(key, tuple.(vals, se)));\njulia> se_dict2= OrderedDict(Pair.(key, se));\njulia> t3 == TableCol(\"Column 2\",dict2, se_dict2) == TableCol(\"Column 2\", se_dict1)\ntrue"
},

{
    "location": "advanced_usage.html#A-word-of-caution-about-merging-tables-1",
    "page": "Advanced Usage",
    "title": "A word of caution about merging tables",
    "category": "section",
    "text": "Be careful when you are stacking tables: TexTables does not stack them positionally.  It merges them on the the appropriate column or row keys.So suppose we were constructing a summary statistics table by computing each column and concatenating them together:using RDatasets, TexTables, DataStructures, DataFrames\ndf = dataset(\"datasets\", \"attitude\")\n\n# Compute summary stats for each variable\ncols = []\nfor header in names(df)\n    x = df[header]\n    stats = TableCol(header,\n                     \"N\"     => length(x),\n                     \"Mean\"  => mean(x),\n                     \"Std\"   => std(x),\n                     \"Min\"   => minimum(x),\n                     \"Max\"   => maximum(x))\n    push!(cols, stats)\nendThe right way to put them together horizontally is by calling hcat:julia> tab = hcat(cols[1], cols[2])\n     | Rating | Complaints\n---------------------------\n   N |     30 |         30\nMean | 64.633 |     66.600\n Std | 12.173 |     13.315\n Min |     40 |         37\n Max |     85 |         90But if instead we tried to vertically concatenate them, we would not simply stack the tables the way you might expect.  TexTables will merge the two columns vertically on their column indexes, which in this case are _different_.julia> [cols[1]; cols[2]]\n     | Rating | Complaints\n---------------------------\n   N | 30     |\nMean | 64.633 |\n Std | 12.173 |\n Min | 40     |\n Max | 85     |\n   N |        | 30\nMean |        | 66.600\n Std |        | 13.315\n Min |        | 37\n Max |        | 90This result, while perhaps unintuitive, is by design.  cols[1] and cols[2] really are not of a shape that could be put together vertically (at least not without overwriting one of their column names). But rather than give an error when some keys are not present, TexTables tries it\'s best to put them together in the order you\'ve requested.  This behavior is essential for horizontally concatenating two regression tables with summary statistics blocks at the bottom. In general, whenever you concatenate two tables, they need to have the same structure in the dimension that they are not being joined upon, or the results will probably not be what you expected."
},

]}
