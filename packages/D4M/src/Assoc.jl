
#Allow sorting between Numbers and Strings
isless(A::Number,B::AbstractString) = false
isless(A::AbstractString,B::Number) = true


StringOrNumArray = Union{AbstractString,Array,Number}
UnionArray = Array{Union{AbstractString,Number}}
SparseOrTranspose = Union{AbstractSparseMatrix,Adjoint{<:Any,<:SparseMatrixCSC},Transpose{<:Any,<:SparseMatrixCSC}}

#Creation of Assoc require StrUnique to split Single-Character-separated String Sequence.
#include("stringarrayhelpers.jl")

#=
Type Assoc (Associative Array)
Support a 
=#


struct Assoc
# TODO: "type" being depreciated, should change to struct or mutable struct
# Should be struct- operations on A return a new Assoc, not a changed A.
    row::UnionArray
    col::UnionArray
    val::UnionArray
    A::SparseOrTranspose
    
    # default uses min, should it be sum?
    Assoc(rowIn::StringOrNumArray,colIn::StringOrNumArray,valIn::StringOrNumArray) = Assoc(rowIn,colIn,valIn,min) 
    Assoc(row::Array{Int64}, col::Array{Int64},val::Array{Int64},A::SparseOrTranspose) = new(row,col,val,A)
    #Setting Default Function

    #Assoc(rowIn::UnionArray,colIn::UnionArray,A::Adjoint{<:Any,<:SparseMatrixCSC}) = new(row,col,A)
    

    function Assoc(rowIn::Array{Union{AbstractString,Number}}, colIn::Array{Union{AbstractString,Number}}, valIn::Array{Union{AbstractString,Number}}, AIn::SparseOrTranspose)
        if (!isempty(valIn) && isassigned(valIn)) && isa(valIn[1],Number)
            valIn = convert(Array{Union{AbstractString,Number}},[1.0])
        end
        return new(rowIn,colIn,valIn,AIn)
    end

    function Assoc(rowIn::StringOrNumArray,colIn::StringOrNumArray,valIn::StringOrNumArray,funcIn::Function)
        if isempty(rowIn) || isempty(colIn) || isempty(valIn)
            # testing needed for isemtpy, for Matlab isemtpy is always possible TODO 
            # Seems to work okay with String or NumArray type hard defined, Union type untested. 
            # Should keep an eye.
            x = Array{Union{AbstractString,Number}}(undef)
            return Assoc(x,x,x,spzeros(0,0));
        end

        # Convert any scalar numbers to an array
        if isa(rowIn,Number)
            rowIn = Array{Union{AbstractString,Number},1}([rowIn])
        end
        if isa(colIn,Number)
            colIn = Array{Union{AbstractString,Number},1}([colIn])
        end
        if isa(valIn,Number)
            valIn = Array{Union{AbstractString,Number},1}([valIn])
        end

        # row, col, and val are always searchsortedfirst
        # i, j, and v are passed into the sparse constructor
        i = rowIn;
        j = colIn;
        v = valIn;
        row = rowIn;
        col = colIn;
        val = valIn;
        
        if isa(rowIn,AbstractString)
            row, i_out2in, i = StrUnique(rowIn); 
        else 
            # Get unique sorted keys
            row = unique(i)
            sort!(row)

            # Find index of row keys from triples in row (int indices for sparse matrix)
            i = convert(AbstractArray{Int64},[searchsortedfirst(row,x) for x in i])
        end

        if isa(colIn,AbstractString)
            col, j_out2in, j = StrUnique(colIn);
        else
            # Get unique sorted keys
            col = unique(j)
            sort!(col)

            # Find index of row keys from triples in row (int indices for sparse matrix)
            j = convert(AbstractArray{Int64},[searchsortedfirst(col,x) for x in j])
        end

        if isa(valIn,AbstractString)
            val, v_out2in, v = StrUnique(valIn);           
        else
            val = unique(v)
            sort!(val)
            if (isa(valIn[1],AbstractString))

                # This bit ensures zeros are placed in any location where there are empty strings for value
                if val[1] == ""
                    val = val[2:end]
                    emptyidx = v .== ""
                else
                    emptyidx = []
                end
                v = convert(AbstractArray{Int64},[searchsortedfirst(val,x) for x in v])

                v[emptyidx] .= 0

            else # convert v to Int64 or Float64
                if any(isa.(v,Float64)) # If there are any floats, convert all to float
                    v = convert(AbstractArray{Float64},v)
                else
                    v = convert(AbstractArray{Int64},v)
                end
            end
        end

        # If any of r,c,v are length 1, expands to array with length of others 
        NMax = maximum([length(i) length(j) length(v)]);
        if length(i) == 1
            i = convert(AbstractArray{Int64},repeat(i,NMax))
        end
        if length(j) == 1
            j = convert(AbstractArray{Int64},repeat(j,NMax))
        end
        if length(v) == 1
            v = convert(AbstractArray{Int64},repeat(v,NMax))
        end

        # Create the sparse matrix
        # If the values are string, assume that there are duplicates
        # and take the earliest one ( the numbers should be the same)
        if isa(val[1],AbstractString) 
            A = sparse(i,j,v,length(row),length(col),min);
        else
            A = sparse(i,j,v,length(row),length(col),(+));
        end
        
        # If values are Numbers (not strings), actual values are stored in the sparse matrix
        # and "val" is set to [1.0] as a signal
        if isa(val[1],Number)
            val = convert(Array{Union{AbstractString,Number}},[1.0])
        end
        return new(row,col,val,A)
    end
end

#=
Returns an empty Associative Array
=#
function emptyAssoc()
    Assoc([],[],[])
end

#=
size: Return the dimensions of the Associative Array
=#
function size(A::Assoc)
    return size(A.A)
end

#=
nnz: Return the number of nonzeros in an Associative Array
=#
function nnz(A::Assoc)

    if isa(A.A,LinearAlgebra.Adjoint) || isa(A.A, LinearAlgebra.Transpose)
        return nnz(A.A.parent)
    else
        return nnz(A.A)
    end
end

#=
isempty : check if given Assoc is empty.
Note: Assoc can be considered empty even if there are mapping for potential or past values.
=#
function isempty(A::Assoc)
    return isempty(A.A)
end


#=
Adding related operations for Assoc_orig
=#
include("./Assoc/getindex.jl")
include("./Assoc/condense.jl")
include("./Assoc/operations.jl")
include("./Assoc/print.jl")
include("./Assoc/accessor.jl")
include("./Assoc/put.jl")
include("./Assoc/convert.jl")
include("./Assoc/broadcast.jl")
include("./Assoc/io.jl")
include("./Assoc/convertvals.jl")
include("./Assoc/bfs.jl")
#include("./Assoc_orig/find.jl")
#include("./Assoc_orig/no.jl")
#include("./Assoc_orig/isempty.jl")
#include("./Assoc_orig/logical.jl")
#include("./Assoc_orig/and.jl")
#include("./Assoc_orig/transpose.jl")
#include("./Assoc_orig/multiply.jl")
#include("./Assoc_orig/sqIn.jl")
#include("./Assoc_orig/sqOut.jl")
#include("./Assoc_orig/diag.jl")
#include("./Assoc_orig/plus.jl")
#include("./Assoc_orig/deepcondense.jl")
#include("./Assoc_orig/lt.jl")
#include("./Assoc_orig/gt.jl")
#include("./Assoc_orig/jld.jl")
#include("./Assoc_orig/equal.jl")
#include("./Assoc_orig/minus.jl")
#include("./Assoc_orig/emptyAssoc.jl")
#include("./Assoc_orig/size.jl")
#include("./Assoc_orig/printTriple.jl")
#include("./Assoc_orig/nnz.jl")
#include("./Assoc_orig/printFull.jl")
#include("./Assoc_orig/str2num.jl")

########################################################
# D4M: Dynamic Distributed Dimensional Data Model
# Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)
# Software Engineer: Alexander Chen (alexc89@mit.edu)
########################################################

