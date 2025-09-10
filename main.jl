############ Boot (main.jl) ############
using TOML, URIs
using .HttpClient, .HttpService, .HttpServer

function loadConfig(path)
    cfg = TOML.parsefile(path)
    return (
        server = (address = String(cfg["server"]["address"]),
                  port    = Int(cfg["server"]["port"])),
        database = (host = String(cfg["database"]["host"]),
                    port = Int(cfg["database"]["port"]),
                    user = String(cfg["database"]["user"]),
                    password = String(cfg["database"]["password"])),
    )
end

cfg    = loadConfig("config.toml")
dbUri  = URIs.URI(scheme="http", host=cfg.database.host, port=cfg.database.port)
client = HttpClient.Client(dbUri)
svc    = HttpService.Service(client)

HttpServer.start(HttpServer.ServerDeps(svc); address=cfg.server.address, port=cfg.server.port)
