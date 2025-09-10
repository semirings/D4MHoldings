module HTTPClient

using HTTP
using JSON3

const dbUrl = Ref{String}()

export setQuery, getNextChunk

const cookieJar = HTTP.Cookies.CookieJar()

function setQuery(payload::String, tableName::String)
    data = Dict("payload" => payload, "tableName" => tableName)
    response = HTTP.post(
        "http://localhost:8080/qry/init",
        ["Content-Type" => "application/json"],
        JSON3.write(data);
        cookies = cookieJar
    )
    return JSON3.read(response.body)
end

function getNextChunk()
    response = HTTP.get("http://localhost:8080/qry/next"; cookies = cookieJar)
    return JSON3.read(response.body)
end

function jsonToAssocDedup(parsed)
    aa = Dict{Tuple{String,String}, String}()

    for entry in parsed.rows
        key = (String(entry.row), String(entry.col))
        aa[key] = String(entry.val)
    end

    rows = String[]
    cols = String[]
    vals = String[]

    for ((r, c), v) in aa
        push!(rows, r)
        push!(cols, c)
        push!(vals, v)
    end

    return Assoc(rows, cols, vals)
end

function query()
    T = getNextChunk()
    A = jsonToAssocDedup(T)
    return A
end

end # module
