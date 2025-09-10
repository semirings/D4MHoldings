############ HttpServer.jl ############
module HttpServer
using HTTP, JSON3, Logging
using ..HttpService

struct ServerDeps
    service::HttpService.Service
end

function start(deps::ServerDeps; address::AbstractString="0.0.0.0", port::Integer=8080)
    router = HTTP.Router()

    HTTP.@register(router, "POST", "/qry/init") do req
        try
            obj = JSON3.read(io = IOBuffer(req.body))
            payload   = String(obj["payload"])
            tableName = String(obj["tableName"])

            result = HttpService.setQuery(deps.service, payload, tableName)
            return HTTP.Response(200, JSON3.write(result); headers = ["Content-Type" => "application/json"])
        catch e
            @error "request failed" error=e
            return HTTP.Response(500, "internal error")
        end
    end

    @info "HTTP server listening" address port
    HTTP.serve(router, address, port)
end

end # module
