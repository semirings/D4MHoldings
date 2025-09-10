# Various ways to get part of an Associative Array (indexing, diag, or >,<,==)
using LinearAlgebra

# This is the getindex function for Assoc, the Associate Array.
#import Base.getindex
StringOrNumArray  = Union{AbstractString,Array,Number}

#The Base getindex function which most higher level function would call upon.
function getindex(A::Assoc, i::Array{Int64}, j::Array{Int64})
    #Check if A is empty
    if isempty(A.A)
        return Assoc([1],[1],0,(+))
    end

    # Need to check if numeric values- don't move into Vals, keep in A.A
    if A.val == [1.0]
        return condense(Assoc(A.row[i],A.col[j],A.val,A.A[i,j]))
    else
        return deepCondense(Assoc(A.row[i],A.col[j],A.val,A.A[i,j]))
    end
end

#Singular Case
getindex(A::Assoc,i::Any) = getindex(A,i,:)

PreviousTypes = Array{Int64}

#Variations by derivations
#Each of the additional type would call upon the base functions above.
#It does so by building up row and column combinations of the new type with all previous types.

#Get index with basic addressing.
#Variations between Element, Array, Colon, AbstractRange
getindex(A::Assoc,i::Array{Union{AbstractString,Number}},j::PreviousTypes)                          = getindex(A,findall(x-> x in i,A.row),j)
getindex(A::Assoc,i::PreviousTypes,j::Array{Union{AbstractString,Number}})                          = getindex(A,i,findall(x-> x in j,A.col))
getindex(A::Assoc,i::Array{Union{AbstractString,Number}},j::Array{Union{AbstractString,Number}})    = getindex(A,findall(x-> x in i,A.row),findall(x-> x in j,A.col))

PreviousTypes = Union{PreviousTypes,Array{Union{AbstractString,Number}}}

getindex(A::Assoc,i::Int64,j::PreviousTypes)         = getindex(A,[i],j)
getindex(A::Assoc,i::PreviousTypes,j::Int64)         = getindex(A,i,[j])
getindex(A::Assoc,i::Int64,j::Int64)                 = getindex(A,[i],[j])

PreviousTypes = Union{PreviousTypes,Int64}

getindex(A::Assoc,i::Colon,j::PreviousTypes)         = getindex(A,1:size(A.row,1),j)
getindex(A::Assoc,i::PreviousTypes,j::Colon)         = getindex(A,i,1:size(A.col,1))
getindex(A::Assoc,i::Colon,j::Colon)                 = getindex(A,1:size(A.row,1),1:size(A.col,1))

PreviousTypes = Union{PreviousTypes,Colon}

getindex(A::Assoc,i::AbstractRange,j::PreviousTypes)         = getindex(A,collect(i),j)
getindex(A::Assoc,i::PreviousTypes,j::AbstractRange)         = getindex(A,i,collect(j))
getindex(A::Assoc,i::AbstractRange,j::AbstractRange)                 = getindex(A,collect(i),collect(j))

PreviousTypes = Union{PreviousTypes,AbstractRange}

function convertrange(Akeys,r::AbstractString)
    sep = r[end:end]
    idx = 1
    while occursin(sep*":"*sep,r[idx:end]) 
        idx = findfirst(sep*":"*sep,r)[1]+1
        from = 1:idx-2
        to = idx+2:length(r)

        if occursin(sep,r[1:idx-2])
            from = findprev(sep,r,idx-2)[1]:idx-2
        end
        if occursin(sep,r[idx+1:end-1])
            to = idx+2:findnext(sep,r,idx+2)[1]-1
        end
        newKeys = join(Akeys[searchsortedfirst(Akeys,r[from]):searchsortedlast(Akeys,r[to])],sep)
        if !isempty(newKeys)
            r = r[1:from[1]-1]*newKeys*r[to[end]+1:end]
        else
            r = r[1:from[end]+1]*r[to[1]:end]
        end
            idx = from[end]+length(newKeys)
    end
    return r
end

#Variations of Single Sequence Strings that is separated by a single character separator.
getindex(A::Assoc, i::AbstractString, j::PreviousTypes)   = getindex(A, findall( x -> in(x,StrUnique(convertrange(A.row,i))[1]),A.row), j)
getindex(A::Assoc, i::PreviousTypes ,j::AbstractString)   = getindex(A, i ,findall( x -> in(x,StrUnique(convertrange(A.col,j))[1]),A.col))
getindex(A::Assoc, i::AbstractString ,j::AbstractString)  = getindex(A, findall( x -> in(x,StrUnique(convertrange(A.row,i))[1]),A.row) ,findall( x -> in(x,StrUnique(convertrange(A.col,j))[1]),A.col))

PreviousTypes = Union{PreviousTypes,AbstractString}


#Variations by Regex
getindex(A::Assoc, i::Regex, j::PreviousTypes)  = getindex(A, findall( x -> occursin(i,x),A.row), j)
getindex(A::Assoc, i::PreviousTypes, j::Regex)  = getindex(A, i, findall( x -> occursin(j,x),A.col))
getindex(A::Assoc, i::Regex, j::Regex)          = getindex(A, findall( x -> occursin(i,x),A.row), findall( x -> occursin(j,x),A.col))


PreviousTypes = Union{PreviousTypes,Regex}


#Variation with StartsWith
struct StartsWith
    inputString::AbstractString
end

# returns an array of indices; 
# the corresponding subarray of getrow/getcol is what's called for by startswith
function StartsWithHelper(Ar::Array{Union{AbstractString,Number}},S::StartsWith)
    str_list = []
    if S.inputString[end] == ','
        str_list,tmp = StrUnique(S.inputString)
    else
        str_list = [S.inputString]
    end
    result_indice = Array{Int64,1}()
    for str in str_list
        str_result_first = searchsortedfirst(Ar,str)
        str_result_last = searchsortedlast(Ar,str*string(Char(255)))
        if str_result_first <= str_result_last
            [push!(result_indice,x) for x in str_result_first:str_result_last]
        end
    end
    return result_indice
end

getindex(A::Assoc,i::PreviousTypes,j::StartsWith) = getindex(A,i,StartsWithHelper(getcol(A),j))
getindex(A::Assoc,i::StartsWith,j::PreviousTypes) = getindex(A,StartsWithHelper(getrow(A),i),j)
getindex(A::Assoc,i::StartsWith,j::StartsWith) = getindex(A,StartsWithHelper(getrow(A),i),StartsWithHelper(getcol(A),j))

PreviousTypes = Union{PreviousTypes,StartsWith}

#=
> : get a new Assoc where all of the elements of input Assoc mataches the given Element.
=#
function >(A::Assoc, E::Union{AbstractString,Number})
    if (isa(E,Number) & (A.val ==[1.0])  )
        tarIndex = E
    else
        tarIndex = searchsortedlast(getval(A),E)
    end

    if isa(A.A,LinearAlgebra.Adjoint) || isa(A.A, LinearAlgebra.Transpose)
        rowkey, colkey, valkey = findnz(SparseMatrixCSC(A.A))
    else
        rowkey, colkey, valkey = findnz(A.A)
    end
    mapping = findall( x-> x > tarIndex, valkey)
    rows, cols, vals = find(A)

    outA = Assoc(rows[mapping],cols[mapping],vals[mapping])

    if A.val==[1.0]
        outA = putVal(outA,A.val)
    end
    
    return outA
end

>(E::Union{AbstractString,Number},A::Assoc) = (A < E)

#=
< : get a new Assoc where all of the elements of input Assoc mataches the given Element.
=#
function <(A::Assoc, E::Union{AbstractString,Number})
    if (isa(E,Number) & (A.val ==[1.0])  )
        tarIndex = E
    else
        tarIndex = searchsortedfirst(A.val,E)
    end

    if isa(A.A,LinearAlgebra.Adjoint) || isa(A.A, LinearAlgebra.Transpose)
        rowkey, colkey, valkey = findnz(SparseMatrixCSC(A.A))
    else
        rowkey, colkey, valkey = findnz(A.A)
    end
    mapping = findall( x-> x < tarIndex, valkey)
    rows, cols, vals = find(A)

    outA = Assoc(rows[mapping],cols[mapping],vals[mapping])

    if A.val==[1.0]
        outA = putVal(outA,A.val)
    end
    
    return outA
end

<(E::Union{AbstractString,Number},A::Assoc) = (A > E)

#=
== : get a new Assoc where all of the elements of input Assoc matches the given Element.
=#
(==)(A::Assoc,E::Union{AbstractString,Number}) = equal(A::Assoc,E::Union{AbstractString,Number})
function equal(A::Assoc, E::Union{AbstractString,Number})
    if (isa(E,Number) && (A.val == [1.0])  ) 
        tarIndex = E
    else
        tarIndex = searchsortedfirst(A.val,E)
        if !(E == getval(A)[tarIndex])
            tarIndex = 0
        end
    end
    
    if isa(A.A,LinearAlgebra.Adjoint) || isa(A.A, LinearAlgebra.Transpose)
        rowkey, colkey, valkey = findnz(SparseMatrixCSC(A.A))
    else
        rowkey, colkey, valkey = findnz(A.A)
    end
    mapping = findall( x-> x == tarIndex, valkey)
    rows,cols,vals = find(A)

    Aout = Assoc(rows[mapping],cols[mapping],vals[mapping])

    # May not need this anymore
    if A.val==[1.0]
        Aout = putVal(Aout,A.val)
    end
    
    return Aout
end

==(E::Union{AbstractString,Number},A::Assoc) = (A == E)

function bounded(A::Assoc, E1::Union{AbstractString,Number}, E2::Union{AbstractString,Number})
    if (isa(E1,Number) & (A.val ==[1.0])  )
        tarIndex1 = E1
    else
        tarIndex1 = searchsortedfirst(A.val,E1)
    end

    if (isa(E2,Number) & (A.val ==[1.0])  )
        tarIndex2 = E2
    else
        tarIndex2 = searchsortedfirst(A.val,E2)
    end

    if isa(A.A,LinearAlgebra.Adjoint) || isa(A.A, LinearAlgebra.Transpose)
        rowkey, colkey, valkey = findnz(SparseMatrixCSC(A.A))
    else
        rowkey, colkey, valkey = findnz(A.A)
    end
    mapping = findall( x-> tarIndex1 <= x <= tarIndex2, valkey)
    rows, cols, vals = find(A)

    outA = Assoc(rows[mapping],cols[mapping],vals[mapping])

    if A.val==[1.0]
        outA = putVal(outA,A.val)
    end
    
    return outA
end

function strictbounded(A::Assoc, E1::Union{AbstractString,Number}, E2::Union{AbstractString,Number})
    if (isa(E1,Number) & (A.val ==[1.0])  )
        tarIndex1 = E1
    else
        tarIndex1 = searchsortedfirst(A.val,E1)
    end

    if (isa(E2,Number) & (A.val ==[1.0])  )
        tarIndex2 = E2
    else
        tarIndex2 = searchsortedfirst(A.val,E2)
    end

    if isa(A.A,LinearAlgebra.Adjoint) || isa(A.A, LinearAlgebra.Transpose)
        rowkey, colkey, valkey = findnz(SparseMatrixCSC(A.A))
    else
        rowkey, colkey, valkey = findnz(A.A)
    end
    mapping = findall( x-> tarIndex1 < x < tarIndex2, valkey)
    rows, cols, vals = find(A)

    outA = Assoc(rows[mapping],cols[mapping],vals[mapping])

    if A.val==[1.0]
        outA = putVal(outA,A.val)
    end
    
    return outA
end


#=
diag : Output the diagonal of input Assoc A.
Outputs the Assoc with only the diagonal elements of A.
=#
function diag(A::Assoc)
    # Check if numeric values first
    if A.val == [1.0]
        return Assoc(A.row,A.col,A.val,dropzeros!(sparse(diagm(0 => diag(A.A)))))
    else
        return deepCondense(Assoc(A.row,A.col,A.val,sparse(diagm(0 => diag(A.A)))))
    end
end

########################################################
# D4M: Dynamic Distributed Dimensional Data Model
# Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)
# Software Engineer: Alexander Chen (alexc89@mit.edu)
########################################################
