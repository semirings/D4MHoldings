############ HttpClient.jl ############
module D4MHttpClient
using URIs: URI, HTTP, JSON3

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

function getQuery(client::Client, query::String, tableName::String)
    # build URL with query params: /qry/init?tableName=...&q=...
    base  = endpoint(client, "/qry/init")
    qs    = "tableName=$(urlesc(tableName))&q=$(urlesc(query))"
    url   = string(URIs.URI(base; query = qs))

    res = HTTP.get(
        url;
        cookies         = client.cookieJar,
        readtimeout     = client.readTimeout,
        connect_timeout = client.connectTimeout,
        status_exception = false,   # let us inspect non-2xx
    )

    if res.status != 200
        error("GET /qry/init failed: $(res.status) $(String(res.body))")
    end
    return JSON3.read(res.body)     # default: JSON3.Object
end

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

export Client, getQuery, postQuery

end # module
