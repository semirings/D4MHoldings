module HttpService

using CSV
using DataFrames
using HTTP

export readCsvService

function readCsvService()
    df = CSV.read("/Users/gcr/d4m.Wk/A.csv", DataFrame)
    rows = [join(row, ", ") for row in eachrow(df)]
    body = join(rows, "\n")
    return HTTP.Response(200, body)
end

end # module
