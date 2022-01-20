using MatrixMicroscopeUtils
using Documenter

DocMeta.setdocmeta!(MatrixMicroscopeUtils, :DocTestSetup, :(using MatrixMicroscopeUtils); recursive=true)

makedocs(;
    modules=[MatrixMicroscopeUtils],
    authors="Mark Kittisopikul <kittisopikulm@janelia.hhmi.org> and contributors",
    repo="https://github.com/mkitti/MatrixMicroscopeUtils.jl/blob/{commit}{path}#{line}",
    sitename="MatrixMicroscopeUtils.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://mkitti.gitlab.io/MatrixMicroscopeUtils.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
