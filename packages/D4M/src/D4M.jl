
#Module for D4M
module D4M

    using LinearAlgebra, SparseArrays, DelimitedFiles

    import SparseArrays: nnz, diag
    import Base: &, ==, >, <, -, *, +, /
    import Base: isless, getindex, isempty, print, size, sum, transpose,
            Array, Matrix, adjoint, broadcast
     import JLD: writeas, readas

    export  Assoc,
            StartsWith,
            CatKeyMul, CatValMul,
            CatStr, SplitStr, NumStr,
            col2type, val2col,
            ReadCSV, WriteCSV, 
            # writeas, readas, 
            print, printFull, printTriple,
            norow, nocol,
            logical, str2num, convertvals,
            sqIn, sqOut,
            putAdj, putRow, putCol, putVal,
            getadj, getrow, getcol, getval, find,
            #saveassoc, loadassoc,
            OutDegree, InDegree, diag,
            bounded, strictbounded, adjbfs

    include("Assoc.jl") # Associative Array

    #Helper functions for parsing
    include("parsinghelpers.jl")
    #Helper functions for working with strings and string arrays
    include("stringarrayhelpers.jl")
end


########################################################
# D4M: Dynamic Distributed Dimensional Data Model
# Architect: Dr. Jeremy Kepner (kepner@ll.mit.edu)
# Software Engineer: Alexander Chen (alexc89@mit.edu)
########################################################




