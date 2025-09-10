# TODO make consistent with Graphulo's degree count, which only adds 1 (like logical)
function adjbfs(A::Assoc, v0::AbstractString, numsteps::Number, minDegree = 1::Number, maxDegree = 2^31 - 1::Number; takeunion = false, nodiag = false)
    # compute the outdegrees.
    # If nodiag is true, then the diagonal of the adjacency matrix will be ignored. (Handy when the diagonal represents edge counts, rather than self-loops)
    if nodiag
        Anodiag = A-diag(A)
        Anodiag = Assoc(Anodiag.row,Anodiag.col,Anodiag.val,dropzeros!(Anodiag.A))
        Adeg = sum(Anodiag, 1)
    else
        Anodiag = A
        Adeg = sum(A, 1)
    end

    return adjbfs(Anodiag, Adeg, v0, numsteps, minDegree, maxDegree; takeunion = takeunion)

end


function adjbfs(A::Assoc, Adeg::Assoc, v0::AbstractString, numsteps::Number, minDegree = 1::Number, maxDegree = 2^31 - 1::Number; takeunion = false)
    
    vk = v0
    Ak = Assoc("", "", "")

    if vk == ""
        println("No start nodes.")
    end

    if takeunion
        Akall = Assoc("", "", "")
    end

    for i = 1:numsteps
        # println("step " * string((i)))
        # println("vk " * string((vk)))
        
        if isa(vk, Array) && ndims(vk) == 0 # meaning no nodes reachable from previous step's uk (or v0 is '').
            Ak = Assoc("", "", "")
            println("Stopped BFS after step " * string(i) *  "; no nodes in search set.")
            break
        end


        ukAssoc = bounded(Adeg[:,vk], minDegree, maxDegree)
        uk = ukAssoc.col  # filtered for degree

        # println("uk " * string(uk))
        if ndims(uk) == 0
            Ak = Assoc("", "", "")
        else
            Ak = A[uk,:]   # submatrix within reach of filtered neighbors
            if takeunion
                Akall = Ak + Akall
            end
        end

        vk = Ak.col   # nodes exactly k hops away
    end
    if takeunion
        Ak = Akall
    end

    return Ak

end