using Documenter, MASW

makedocs(;
    modules=[MASW],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/kura-okubo/MASW.jl/blob/{commit}{path}#L{line}",
    sitename="MASW.jl",
    authors="kurama",
    assets=String[],
)

deploydocs(;
    repo="github.com/kura-okubo/MASW.jl",
)
