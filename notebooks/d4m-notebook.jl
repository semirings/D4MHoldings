### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 435b79ec-965e-11f0-2b5b-d5f5fb037ad8
begin
    using Pkg
    # point to the *package root* (must contain Project.toml and src/D4MHoldings.jl)
    Pkg.develop(path="/Users/gcr/d4m.Wk/D4MHoldings/packages/D4M")
	Pkg.develop(path="/Users/gcr/d4m.Wk/D4MHoldings/packages/D4MHttp")
	Pkg.instantiate()
end




# ╔═╡ b4d9a2c0-4433-4dd7-b35d-0fff19b17ba1
begin
	using Revise
	using D4M, D4MHttp
end

# ╔═╡ Cell order:
# ╠═435b79ec-965e-11f0-2b5b-d5f5fb037ad8
# ╠═b4d9a2c0-4433-4dd7-b35d-0fff19b17ba1
