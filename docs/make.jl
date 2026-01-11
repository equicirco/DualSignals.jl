using Documenter
using DualSignals

DocMeta.setdocmeta!(DualSignals, :DocTestSetup, :(using DualSignals); recursive = true)

makedocs(
    modules = [DualSignals],
    sitename = "DualSignals.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        assets = [
            "assets/deepwiki-chat.css",
            "assets/deepwiki-chat.js",
        ],
        logo = "assets/logo-light.png",
        logo_dark = "assets/logo-dark.png",
    ),
    pages = [
        "Home" => "index.md",
        "Data Model" => "data-model.md",
        "API" => "api.md",
        "Data IO" => "io.md",
        "Analysis" => "analysis.md",
        "Reporting" => "reporting.md",
        "JuMP Adapter" => "jump.md",
        "Notebooks" => "notebooks.md",
        "Examples" => [
            "IEEE-14 OPF" => "example-ieee14-opf.md",
            "CGE" => "stdcge.md",
        ],
    ],
)

deploydocs(
    repo = "github.com/equicirco/DualSignals.jl.git",
    devbranch = "main",
    versions = [
        "stable" => "v^",
        "v#.#",
        "dev" => "dev",
    ],
)
