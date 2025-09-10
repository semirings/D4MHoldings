# HttpServer.jl
module HttpServer
using HTTP, JSON3, Logging

# Keep handles so we can shut down programmatically
const _serverRef = Ref{HTTP.Servers.Server}()
const _taskRef   = Ref{Task}()

function start(handler; address="0.0.0.0", port::Integer=8080)
    router = handler  # or build your router here

    srv = HTTP.Servers.Server(router)
    _serverRef[] = srv

    # Run the server in an async task and block main with wait(...)
    t = @async try
        HTTP.serve(srv, address, port; verbose=false)
    catch e
        @error "HTTP.serve crashed" error=e
        rethrow()
    end
    _taskRef[] = t

    # Ensure graceful shutdown on process exit (e.g., SIGTERM from supervisord)
    atexit(() -> _shutdown())

    @info "Listening" address port
    wait(t)  # <- blocks here until shutdown
end

function stop()
    _shutdown()
end

function _shutdown()
    try
        if !isassigned(_serverRef); return; end
        @info "Shutting down HTTP server..."
        HTTP.shutdown(_serverRef[])
        if isassigned(_taskRef)
            wait(_taskRef[])   # drain the serve task
        end
    catch e
        @warn "Error during shutdown" error=e
    end
end

end # module
