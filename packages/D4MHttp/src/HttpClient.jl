############ HttpClient.jl ############
module HttpClient
using URIs, HTTP, JSON3

struct Client
    baseUri::URIs.URI
    cookieJar::HTTP.Cookies.CookieJar
    readTimeout::Float64
    connectTimeout::Float64
end

function Client(baseUri::URIs.URI; cookieJar=HTTP.Cookies.CookieJar(), readTimeout=15.0, connectTimeout=10.0)
    new(baseUri, cookieJar, readTimeout, connectTimeout)
end

endpoint(c::Client, path::AbstractString) =
    URIs.URI(scheme=c.baseUri.scheme, host=c.baseUri.host, port=c.baseUri.port,
             path = startswith(path, "/") ? path : "/" * path)

function postQuery(client::Client, payload::String, tableName::String)
    body = JSON3.write((; payload, tableName))
    res = HTTP.post(
        string(endpoint(client, "/qry/init")),
        ["Content-Type" => "application/json"],
        body;
        cookies = client.cookieJar,
        readtimeout = client.readTimeout,
        connect_timeout = client.connectTimeout,
    )
    return JSON3.read(res.body)
end

end # module
