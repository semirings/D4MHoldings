# Functions for changing the values of an associative array

#=
Reduce all value to logical, checking if that cell is empty
=#

using SparseArrays,LinearAlgebra

logical(A::Assoc) = Assoc(copy(A.row),copy(A.col),promote([1.0],A.val)[1],LinearAlgebra.fillstored!(dropzeros!(copy(A.A)),1))


function parsehelper(type, v)
    parsed = tryparse(type, v)
    if parsed===nothing
        return 1
    end
    return parsed
end

function str2num(A::Assoc, type::Type=Int)
    if ~(type<:Number)
        println("Type not number")
    return nothing
    end
    r,c,v = find(A)
    v = parsehelper.(type, v)
    # TODO do mixed types of values exist? If so, use them
    A = Assoc(r,c,v)
end

function str2num(type::Type, A::Assoc)
    return str2num(A, type)
end

# TODO: Write num2str

#=
convert all entries to a certain type
=#

function convertvals(type, A::Assoc)
    r,c,v = find(A)
    v = convert.(type, v)
    A = Assoc(r,c,v)
end

########################################################
# D4M: Dynamic Distributed Dimensional Data Model
# Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)
# Software Engineer: Alexander Chen (alexc89@mit.edu)
########################################################

