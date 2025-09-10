
#=
Protected Accessor Function for User.
=#
# gets the sparse matrix
function getadj(A::Assoc)
    return copy(A.A)
end

# getcol, getrow, getval return range objects if possible
# if not, they return copies of the col, rw, val parts of Assoc's struct
function getcol(A::Assoc)
    if isempty(A)
        return Union{AbstractString, Number}[]
    else
        if isa(A.col[1], AbstractString) || ~(size(A.A,2) == A.col[end])
            return copy(A.col)
        end
        return 1:size(A.A,2)
    end
end

function getrow(A::Assoc)
    if isempty(A)
        return Union{AbstractString, Number}[]
    else
        if isa(A.row[1], AbstractString) || ~(size(A.A,1) == A.row[end])
            return copy(A.row)
        end
        return 1:size(A.A,1)
    end
end

function getval(A::Assoc)
    if isempty(A)
        return Union{AbstractString, Number}[]
    else
        if isa(A.val[1], AbstractString)
            return copy(A.val)
        end
        return sort(unique(nonzeros(A.A)))
    end
end

#=
find : get the triplet of the input Assoc in three array.  Similar to findnz for sparse.
=#
using SparseArrays

function find(A::Assoc)

    if isa(A.A,LinearAlgebra.Adjoint) || isa(A.A, LinearAlgebra.Transpose)
        row, col, val = findnz(SparseMatrixCSC(A.A))
    else
        row, col, val = findnz(A.A)
    end
    
    val = Array(val)
    n = nnz(A)
    #map if the Associative array isn't numerical
    if ~isempty(A)
        if isa(A.row[1],AbstractString)
            row = [ A.row[row[i]] for i in 1:n]
        end

        if isa(A.col[1],AbstractString)
            col = [ A.col[col[i]] for i in 1:n]
        end
        
        if isa(A.val[1],AbstractString) || A.val != [1.0]
            val = [ A.val[val[i]] for i in 1:n]
        end
    end

    return row, col, val
end

########################################################
# D4M: Dynamic Distributed Dimensional Data Model
# Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)
# Software Engineer: Alexander Chen (alexc89@mit.edu)
########################################################