module HTTPServer

using ..HTTPClient
using HTTP, TOML, CSV, DataFrames
using Logging

export startServer

# Route definitions
const getRoutes = Dict(
    "/" => Base.:(() -> HTTP.Response(200, "Ave Mundus!!")),
    "/health" => Base.:(() -> HTTP.Response(200, "UP")),
    "/readcsv" => Base.:(() -> begin
        df = ReadCSV("/Users/gcr/d4m.Wk/A.csv", DataFrame)
        rows = [join(row, ", ") for row in eachrow(df)]
        body = join(rows, "\n")
        HTTP.Response(200, body)
    end)
)

# Request handling
function handleRequest(method::String, path::String)
    if method == "GET"
        get(getRoutes, path, () -> HTTP.Response(404, "Unknown GET endpoint"))()
    else
        HTTP.Response(405, "Unsupported HTTP method: $method")
    end
end

# Request router
function router(request::HTTP.Request)
    try
        return handleRequest(request.method, request.target)
    catch e
        @error "Router Exception" exception=(e, catch_backtrace())
        return HTTP.Response(500, "Internal Server Error: $(e)")
    end
end

# Server launcher
function startServer()
    config = TOML.parsefile("./config.toml")

    serverIp = config["server"]["address"]
    serverPort = config["server"]["port"]

    dbHost = config["database"]["host"]
    dbPort = config["database"]["port"]

    HTTPClient.set_db_url(dbHost, dbPort)

    HTTP.serve(router, serverIp, serverPort)
end

end # module
