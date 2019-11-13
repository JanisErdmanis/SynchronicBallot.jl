using Documenter

makedocs(sitename="SharedBallot.jl",pages = ["index.md"])

deploydocs(
     repo = "github.com/PeaceFounder/SharedBallot.jl.git",
 )
