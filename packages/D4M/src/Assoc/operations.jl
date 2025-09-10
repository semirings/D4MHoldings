# Various mathematical operations
using Distributed,LinearAlgebra


#=
&,And : Logical & of A and B
=#

(&)(A::Assoc,B::Assoc) = and(A::Assoc,B::Assoc)
function and(A::Assoc, B::Assoc)
    #First, create the row and col of the intersection
    ABrow = intersect(A.row,B.row)
    ABcol = intersect(A.col,B.col)
    #Filling the sparse matrix with 

    AA = spzeros(size(ABrow,1), size(ABcol,1))
    rowMapping = searchsortedmapping(ABrow,A.row)
    colMapping = searchsortedmapping(ABcol,A.col)
    AA = LinearAlgebra.fillstored!(copy(A.A[rowMapping,colMapping]),1)
    AA = round.(Int64,AA)

    BB = spzeros(size(ABrow,1), size(ABcol,1))
    rowMapping = searchsortedmapping(ABrow,B.row)
    colMapping = searchsortedmapping(ABcol,B.col)
    BB = LinearAlgebra.fillstored!(copy(B.A[rowMapping,colMapping]),1)
    BB = round.(Int64,BB)

    ABA = AA .& BB 
    ABA = ABA * 1.0

    return Assoc(ABrow,ABcol,promote([1.0],A.val)[1],ABA) 
end



#=
 +,plus : matrix add for Assoc.

 If Assoc has String in value mapping, the Assoc will be logical instead.
=#


+(A::Assoc,B::Assoc) = plus(A::Assoc,B::Assoc)
function plus(A::Assoc,B::Assoc)
    # Check if A or B is empty
    if isempty(A)
       return B;
    end
    if isempty(B)
       return A;
    end
    
    #Check A,B, if string => Logical
    At = A
    Bt = B
    
    # There can be numberic values in the "vals" this will not work in this case
    if(A.val != [1.0])
        At = logical(A)
    end
    if(A.val != [1.0])
        Bt = logical(B)
    end
    
    ## A+B operation
    ABrow = sortedunion(At.row,Bt.row)
    ABcol = sortedunion(At.col,Bt.col)
    if (size(ABrow,1) == 0 || size(ABcol,1) == 0)
        return Assoc([1],[1],0,(+))
    end

    ABA =  spzeros(length(ABrow),length(ABcol))
    Arow = searchsortedmapping(At.row,ABrow)
    Acol = searchsortedmapping(At.col,ABcol)
    Brow = searchsortedmapping(Bt.row,ABrow)
    Bcol = searchsortedmapping(Bt.col,ABcol)
    ABA[Arow,Acol] += At.A
    ABA[Brow,Bcol] += Bt.A
    AB = Assoc(ABrow,ABcol, Array{Union{AbstractString,Number}}([1.0]), ABA) 
    
    return condense(AB) #Incase of negation
end

# Minus for Associative Arrays
-(A::Assoc,B::Assoc) = minus(A::Assoc,B::Assoc)
function minus(A::Assoc,B::Assoc)
    #Check A,B, if string => Logical
    At = A
    Bt = B
    if(A.val != [1.0])
        At = logical(A)
    end
    if(B.val !=[1.0])
        Bt = logical(B)
    end
    ## A*B operation
    ABrow = sortedunion(At.row,Bt.row)
    ABcol = sortedunion(At.col,Bt.col)
    if (size(ABrow,1) == 0 || size(ABcol,1) == 0)
        return Assoc([1],[1],0,(+))
    end

    ABA =  spzeros(length(ABrow),length(ABcol))
    Arow = searchsortedmapping(At.row,ABrow)
    Acol = searchsortedmapping(At.col,ABcol)
    Brow = searchsortedmapping(Bt.row,ABrow)
    Bcol = searchsortedmapping(Bt.col,ABcol)
    ABA[Arow,Acol] += At.A
    ABA[Brow,Bcol] -= Bt.A
    AB = Assoc(ABrow,ABcol, Array{Union{AbstractString,Number}}([1.0]), ABA) 
    
    return condense(AB) #Incase of negation
end

#=
* : matrix multiply between two Assoc.
If there are Strings in Assoc Value mapping, the Assoc will be reduced to logical.
=#

function *(A::Assoc,B::Assoc)
    #Check A,B, if string => Logical
    At = A
    Bt = B
    if(!isa(A.val[1],Number))
        At = logical(A)
    end
    if(!isa(B.val[1],Number))
        Bt = logical(B)
    end
    ## A*B operation
    #Improve intersect with unique sorted sets
    ABintersect = sortedintersect(At.col,Bt.row)
    
#    if (size(ABintersect,1) == 0)
#        return Assoc([1],[1],0,(+))
#    end
    
#    AintMap = searchsortedmapping(ABintersect,At.col) 
#    BintMap = searchsortedmapping(ABintersect,Bt.row) 

    Aref = @spawn searchsortedmapping(ABintersect,At.col)
    Bref = @spawn searchsortedmapping(ABintersect,Bt.row)
    AintMap = fetch(Aref)
    BintMap = fetch(Bref)
#    AintMap, BintMap = sortedintersectmapping(At.col,Bt.row)

#    AintMap,BintMap = map(x -> searchsortedmapping(x[1],x[2]),[(ABintersect,At.col) (ABintersect, Bt.row)])
    Aref = @spawn At.A[:,AintMap]
    Bref = @spawn Bt.A[BintMap,:]
    AA = fetch(Aref)
    BB = fetch(Bref)

    ABA = AA*BB

    AB = Assoc(At.row,Bt.col,Array{Union{AbstractString,Number}}([1.0]),ABA)

    return condense(AB)
end

#=
 transpose : return the transpose of Given Assoc
=#

function transpose(A::Assoc)
    return Assoc(A.col,A.row,A.val,Transpose(A.A))
end

function adjoint(A::Assoc)
    return Assoc(A.col,A.row,A.val,Adjoint(A.A))
end


#abs: Absolutee value of an inputted numerical associative array.
function abs(A::Assoc)

    if isa(A.val[1],AbstractString)
        error("Attempt to Abs a string valued Associative Array, only numerical Associative Array is accepted")
    end

    AT = deepcopy(A)
    AT.A = abs(AT.A)
    return AT
end

# Same as A'*A, perhaps faster
function sqIn(A::Assoc)
    AtA = deepcopy(A)
    if ! isa(A.val[1], Number)
        AtA = logical(A)
    end

    AA = getadj(AtA)
    AAtAA = AA' * AA

    #=
    AtA.A = AAtAA
    AtA.row = AtA.col
    return AtA
=#
    return Assoc(copy(AtA.col),copy(AtA.col),copy(AtA.val),AAtAA)
end

# Same as A*A', perhaps faster
function sqOut(A::Assoc)
    AtA = deepcopy(A)
    if ! isa(A.val[1], Number)
        AtA = logical(A)
    end

    AA = getadj(AtA)
    AAtAA = AA * AA';

#=
    AtA.A = AAtAA;
    AtA.col = AtA.row
    return AtA
=#
    return Assoc(copy(AtA.row),copy(AtA.row),copy(AtA.val),AAtAA)
end

function sum(A::Assoc, dim::Int64)

    if(A.val != [1.0])
        A = logical(A)
    end

    if(dim == 1)
        return condense(Assoc(promote([1.0],A.row)[1],A.col, promote([1.0],A.val)[1],sparse(sum(A.A, dims = 1))))
    elseif (dim == 2)
    
        return condense(Assoc(A.row,promote([1.0],A.col)[1], promote([1.0],A.val)[1],sparse(sum(A.A, dims = 2))))
    end
end


function sum(A::Assoc)

    if(A.val != [1.0])
        A = logical(A)
    end
    
    sum(A.A)

end

# Matrix multiply, but resulting values are inner dimension keys concatenated together
function CatKeyMul(A::Assoc,B::Assoc)
    if isa(getcol(A)[1],AbstractString) && isa(getrow(B)[1],AbstractString)
        AB = sortedintersect(A.col,B.row)
        A = A[:,AB]
        B = B[AB,:]
        rrr,ccc,vvv = findnz(getadj(A*B))
        ABVal = Array{Union{AbstractString,Number}}(undef,length(rrr))
        for i in 1:length(rrr)
            r = rrr[i]
            c = ccc[i]
            ABvalList = sortedintersect(getcol(A[r,:]),getrow(B[:,c]))
            if length(ABvalList) > 0
                val = join(ABvalList,";")*";"
                ABVal[i] = val
            end
        end
        return Assoc(getrow(A)[rrr],getcol(B)[ccc],ABVal)
    else
        return A*B
    end
    

end

# Matrix multiply, but resulting values are previous values concatenated together
function CatValMul(A::Assoc,B::Assoc)
    if isa(getval(A)[1],AbstractString) && isa(getval(B)[1],AbstractString)
        AB = sortedintersect(A.col,B.row)
        A = A[:,AB]
        B = B[AB,:]
        rrr,ccc,vvv = findnz(getadj(A*B))
        ABVal = Array{Union{AbstractString,Number},1}(undef, length(rrr))
        for i in 1:length(rrr)
            r = rrr[i]
            c = ccc[i]
            ABIntersect = sortedintersect(getcol(A[r,:]),getrow(B[:,c]))
            ABValList = Array{Union{AbstractString,Number},1}(undef, 0)
            for x in ABIntersect
                push!(ABValList,getval(A[r,x*","])[1])
                push!(ABValList,getval(B[x*",",c])[1])
            end
            if length(ABValList) > 0
                val = join(ABValList,";")*";"
                ABVal[i] = val
            end
        end
        return Assoc(getrow(A)[rrr],getcol(B)[ccc],ABVal)
    else
        return A*B
    end
    

end

#=
OutDegree : Calculate the out-degree distribution of graph A
InDegree : Calculate the in-degree distribution of graph A
=#

using SparseArrays

function OutDegree(A)
    if isa(A,Assoc)
        A = A.A
    end
    dout = sum(A,dims = 2)
    dout_i = getindex.(findall(!iszero,dout),1)
    dout_v = dout[dout_i]
    ndout = sum(sparse(dout_i,dout_v,1),dims = 1)
    return ndout
end

function InDegree(A)
    if isa(A,Assoc)
        A = A.A
    end
    din = sum(A,dims = 1)
    din_i = getindex.(findall(!iszero,din),1)
    din_v = din[din_i]
    ndin = sum(sparse(din_i,din_v,1),dims = 1)
    return ndin
end
