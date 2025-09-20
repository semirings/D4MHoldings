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
using D4M, D4MHttp, D4MHttp.D4MHttpClient, URIs

# ╔═╡ 743358b8-f39c-46b3-9d11-56bb49e25fa1
base  = URIs.URI("http://localhost:5102") 

# ╔═╡ dad92c98-a1c7-4e24-a1d5-01858981e63a
ins   = URIs.joinpath(base, "qry")

# ╔═╡ b80d42f7-3b63-4451-a7cb-ade472d1ba6c
ins

# ╔═╡ 2a0a6ba6-5490-4f12-bb42-5fc2690017d8
client = D4MHttpClient.Client("http://localhost:5102")

# ╔═╡ 6d195f14-35f5-4a0c-9b93-2777e8ffa118
rval = postQuery(client, ":Encounter.id", "synth")

# ╔═╡ Cell order:
# ╠═995b4218-8f16-11f0-270b-973b319590b6
# ╠═d9871e9a-4994-4e17-a140-17e5a2a67f30
# ╠═743358b8-f39c-46b3-9d11-56bb49e25fa1
# ╠═dad92c98-a1c7-4e24-a1d5-01858981e63a
# ╠═b80d42f7-3b63-4451-a7cb-ade472d1ba6c
# ╠═2a0a6ba6-5490-4f12-bb42-5fc2690017d8
# ╠═6d195f14-35f5-4a0c-9b93-2777e8ffa118
