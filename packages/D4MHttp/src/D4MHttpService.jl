############ HttpService.jl ############
module D4MHttpService
using ..HttpClient

struct Service
    client::HttpClient.Client
end

"Orchestrates work; calls HttpClient for DB/API"
function postQuery(service::Service, payload::String, tableName::String)
    # Validate, transform, call D4M, etc., as needed
    # Example: delegate to client
    return HttpClient.postQuery(service.client, payload, tableName)
end

end # module
