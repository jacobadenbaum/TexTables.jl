using Documenter
using TexTables

makedocs(
    modules = [TexTables],
    sitename= "TexTables.jl",
    format  = :html,
    clean   = false,
    authors = "Jacob Adenbaum",
    pages   = [
              "Introduction"=>  "index.md",
              "Basic Usage" =>  "basic_usage.md",
              "Advanced Usage"=>"advanced_usage.md"]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo   = "github.com/jacobadenbaum/TexTables.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
