module D4MHttp
# Include submodules

include(joinpath(@__DIR__, "D4MHttpClient.jl"))
include(joinpath(@__DIR__, "D4MHttpServer.jl"))

# Bring them into this module
using D4M
using .D4MHttpClient
using .D4MHttpServer

export start, stop, getQuery, postQuery, D4MHttp.D4MHttpClient: Client

end