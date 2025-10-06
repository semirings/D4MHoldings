### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 995b4218-8f16-11f0-270b-973b319590b6
begin
    using Pkg
    Pkg.activate(@__DIR__)  # or "~/.julia/pluto_notebooks" if that's your Pluto env
    # Remove any stale entry registered under the old name
    try Pkg.rm("D4M") catch end
    # Re-develop from path (corrects the dep graph)
	    Pkg.develop(Pkg.PackageSpec(path="/Users/gcr/d4m.Wk/D4MHoldings/packages/D4M"))
	Pkg.develop(Pkg.PackageSpec(path="/Users/gcr/d4m.Wk/D4MHoldings/packages/D4MHttp"))
    Pkg.resolve(); Pkg.instantiate()
	Pkg.add("URIs")
	Pkg.resolve(); Pkg.instantiate()
end


# ╔═╡ d9871e9a-4994-4e17-a140-17e5a2a67f30
begin
	using D4MHttp.D4MHttpClient: Client, getQuery, postQuery
	using URIs
	
	base  = URI("http://localhost:5102")
	ins   = URIs.joinpath(base, "qry")   # ins :: URI
	client = Client(ins)                 # works
end


# ╔═╡ 6d195f14-35f5-4a0c-9b93-2777e8ffa118
rval = postQuery(client, ":Encounter.id", "synth")

# ╔═╡ Cell order:
# ╠═995b4218-8f16-11f0-270b-973b319590b6
# ╠═d9871e9a-4994-4e17-a140-17e5a2a67f30
# ╠═6d195f14-35f5-4a0c-9b93-2777e8ffa118
