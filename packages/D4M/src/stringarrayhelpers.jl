# This file contains helper functions for working with strings and string arrays in the context of D4M


# String manipulation helper functions useful for parsing
function SplitStr(s12, sep)
    # Given an array of strings, each of which has two substrings joined with a separator,
    # Split the array in two arrays, with each substring in its corresponding array.
    # Assume that separator is always inside the elements of s12
    # Example:
    # input SplitStr(["abc,def", "123,456", "qwe,rty"], ",")
    # output SubString{String}["abc", "123", "qwe"], SubString{String}["def", "456", "rty"])
    strsplit = [split(x, sep)[y] for x in s12, y in 1:2]
    return strsplit[:,1], strsplit[:,2]
end

function NumStr(stringA)
    # Returns the number of elements in a last-char-delimited string
    return length(split(stringA[1:end - 1], stringA[end]))
end

function CatStr(s1::Array, sep::AbstractString, s2::Array)
    # Element-wise concatenation of two arrays of strings,
    # adding sep between each element
    # Assume s1 and s2 are arrays of String
    # Also sep is a string 
    s12 = s1 .* [sep] .* s2  
    return s12
end

# Operations used internally that gain performance benefit on sorted inputs

#=
StrUnique
Get the unique and sorted single-character-separated sequences of strings.  
Also returns the mapping from the original ordering in the given sequence to the outputed sorted version.

Dev Note: 
 * TODO Current the backward mapping doesn't exist, but it doesn't seems to be utilized.
=#
function StrUnique(inputString::AbstractString, csv = false)
    #TODO backwardMapping from unique string to index is not implemented, because there doesn't seem to be a application for such an array
    #Note: The unique output is sorted.
    separator = inputString[end]
    if(csv == true)
        separator = ','
    end
    strA = split(inputString, separator)
    if inputString[end] == separator
        strA = strA[1:end - 1]
    end

    uniqueSeq = unique(strA)
    sort!(uniqueSeq)
    if uniqueSeq[1] == "" #Handle Empty Case
        uniqueSeq = uniqueSeq[2:end]
    end

    forwardMapping = [ searchsortedfirst(uniqueSeq, x) for x in strA]

    backwardMapping = zeros(1, length(forwardMapping))

    return uniqueSeq, backwardMapping, forwardMapping
end

function searchsortedmapping(A::Array, B::Array)
    ## Assume A \in B
    AtoB = Array{Int64,1}()
    temp_index_A = 1
    temp_index_B = 1

    while (temp_index_A <= length(A)) 
        if A[temp_index_A] == B[temp_index_B]
            push!(AtoB, temp_index_B)
            temp_index_A += 1
            temp_index_B += 1
        else
            temp_index_B += 1
        end
    end

    return AtoB
end

function sortedintersect(A::Array, B::Array)
    ABintersect = typeof(A)()
    temp_index_A = 1
    temp_index_B = 1

    while (temp_index_A <= length(A)) & (temp_index_B <= length(B))
        if A[temp_index_A] == B[temp_index_B]
            push!(ABintersect, A[temp_index_A])
            temp_index_A += 1
            temp_index_B += 1
        elseif A[temp_index_A] < B[temp_index_B]
            temp_index_A += 1
        else
            temp_index_B += 1
        end
    end

    return ABintersect
end

function sortedintersectmapping(A::Array, B::Array)
    #Compute intersect of two sorted and unique array.
    #return the mapping from each array to the intersect
    temp_index_A = 1
    temp_index_B = 1
    Amap = Array{Int64,1}()
    Bmap = Array{Int64,1}()

    while (temp_index_A <= length(A)) & (temp_index_B <= length(B))
        if A[temp_index_A] == B[temp_index_B]
            push!(Amap, temp_index_A)
            push!(Bmap, temp_index_B)
            temp_index_A += 1
            temp_index_B += 1
        elseif A[temp_index_A] < B[temp_index_B]
            temp_index_A += 1
        else
            temp_index_B += 1
        end
    end

    return Amap, Bmap
end

function sortedunion(A::Array, B::Array)
    ABintersect = typeof(A)()
    temp_index_A = 1
    temp_index_B = 1

    while (temp_index_A <= length(A)) || (temp_index_B <= length(B))
        if (temp_index_A > length(A))
            push!(ABintersect, B[temp_index_B])
            temp_index_B += 1
        elseif (temp_index_B > length(B))
            push!(ABintersect, A[temp_index_A])
            temp_index_A += 1
        elseif (A[temp_index_A] == B[temp_index_B])
            push!(ABintersect, A[temp_index_A])
            temp_index_A += 1
            temp_index_B += 1
        elseif A[temp_index_A] < B[temp_index_B]
            push!(ABintersect, A[temp_index_A])
            temp_index_A += 1
        else
            push!(ABintersect, B[temp_index_B])
            temp_index_B += 1
        end
    end

    return ABintersect
end

########################################################
# D4M: Dynamic Distributed Dimensional Data Model
# Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)
# Software Engineer: Alexander Chen (alexc89@mit.edu)
########################################################

