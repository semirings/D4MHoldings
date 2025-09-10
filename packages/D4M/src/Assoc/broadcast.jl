import Base: broadcast
import Base.Broadcast.instantiate
using Base.Broadcast: BroadcastStyle, Broadcasted, combine_axes, check_broadcast_axes, instantiate, flatten, broadcastable, _broadcast_getindex, newindex
using SparseArrays

struct AssocStyle <: Broadcast.BroadcastStyle end

Broadcast.BroadcastStyle(::Type{<:Assoc}) = AssocStyle()
Broadcast.BroadcastStyle(::Type{<:Assoc}, ::Type{<:Assoc}) = AssocStyle()

Base.broadcastable(A::Assoc) = A

function Base.similar(bc::Broadcast.Broadcasted{AssocStyle}, ::Type{ElType}) where ElType

    # Scan the inputs for the ArraAssocyAndChar:
    #print(flatten(bc).args)

    ABrow,ABcol = rowcolunion(bc.args...)

    #=
    A,B = flatten(bc).args
    #First, create the row and col of the intersection
    ABrow = sortedintersect(A.row,B.row)
    ABcol = sortedintersect(A.col,B.col)
    #Filling the sparse matrix with 

    
    rowMapping = searchsortedmapping(ABrow,A.row)
    colMapping = searchsortedmapping(ABcol,A.col)
    AA = A.A[rowMapping,colMapping]
    #AA = round(Int64,AA)

    BB = spzeros(size(ABrow,1), size(ABcol,1))
    rowMapping = searchsortedmapping(ABrow,B.row)
    colMapping = searchsortedmapping(ABcol,B.col)
    BB = B.A[rowMapping,colMapping]
    #BB = round(Int64,BB)
    =#
    AA = spzeros(size(ABrow,1), size(ABcol,1))
    # Use the char field of A to create the output
    Assoc(ABrow,ABcol,promote([1.0],ABrow)[1], similar(AA, Base.axes(AA)))
end

#=
function rowcolintersect(A::Assoc,B::Assoc)
    ABrow = sortedintersect(A.row,B.row)
    ABcol = sortedintersect(A.col,B.col)

    return ABrow,ABcol

end
=#

function rowcolunion(A::Assoc,B::Assoc)
    ABrow = sortedunion(A.row,B.row)
    ABcol = sortedunion(A.col,B.col)

    return ABrow,ABcol

end

function rowcolunion(A::Assoc,ABrow,ABcol)
    ABrow = sortedunion(A.row, ABrow)
    ABcol = sortedunion(A.col, ABcol)

    return ABrow,ABcol

end
rowcolunion(A::Assoc,bc::Broadcast.Broadcasted{AssocStyle}) = rowcolunion(A,rowcolunion((bc).args...)...)
rowcolunion(bc::Broadcast.Broadcasted{AssocStyle},B) = rowcolunion(combinedims(bc).args[2],B)


function combinedims(bc::Broadcast.Broadcasted{AssocStyle})
    ABrow,ABcol = rowcolunion(bc.args...)

    return combinedims(bc,ABrow,ABcol)
end

function combinedims(bc::Broadcast.Broadcasted{AssocStyle},ABrow,ABcol)
    
    if isa(bc.args[1],Broadcast.Broadcasted{AssocStyle})
        A = combinedims(bc.args[1],ABrow,ABcol)
    else

        newAA =  spzeros(length(ABrow),length(ABcol))
        Arow = searchsortedmapping(bc.args[1].row,ABrow)
        Acol = searchsortedmapping(bc.args[1].col,ABcol)
        newAA[Arow,Acol] = bc.args[1].A
        A = Assoc(ABrow,ABcol, Array{Union{AbstractString,Number}}([1.0]), newAA) 
        
    end

    if isa(bc.args[2],Broadcast.Broadcasted{AssocStyle})
        B = combinedims(bc.args[2])
    else

        newBA =  spzeros(length(ABrow),length(ABcol))
        Brow = searchsortedmapping(bc.args[2].row,ABrow)
        Bcol = searchsortedmapping(bc.args[2].col,ABcol)
        newBA[Brow,Bcol] = bc.args[2].A
        B = Assoc(ABrow,ABcol, Array{Union{AbstractString,Number}}([1.0]), newBA)
    end

    return Broadcast.broadcasted(bc.f,A,B)
end

function Base.Broadcast.instantiate(bc::Broadcast.Broadcasted{AssocStyle})
    if bc.axes isa Nothing # Not done via dispatch to make it easier to extend instantiate(::Broadcasted{Style})
        bc = combinedims(bc)
        axes = combine_axes(bc.args...)
    else
        axes = bc.axes
        check_broadcast_axes(axes, bc.args...)
    end
    return Broadcasted{AssocStyle}(bc.f, bc.args, axes)
end

Base.@propagate_inbounds Base.Broadcast._broadcast_getindex(A::Assoc, I) = A.A[Base.Broadcast.newindex(A, I)]

function Base.setindex!(A::Assoc, val, inds)
    if ~isnan(val) && val != 0
        A.A[inds[1],inds[2]] = val
    end
end
