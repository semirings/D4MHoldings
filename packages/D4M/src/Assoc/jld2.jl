using JLD2, SparseArrays

#=
Assoc Serialized for saving using JLD2
Note that saving would convert row and col types to number.
=#

# Delimiter for saving- using new line is safer than comma!
del = "\n"
maxchar = typemax(UInt16)-5

SparseOrTranspose = Union{AbstractSparseMatrix,Adjoint{<:Any,<:SparseMatrixCSC},Transpose{<:Any,<:SparseMatrixCSC}}

struct AssocSerial
    rowstr::Array{AbstractString,1}
    colstr::Array{AbstractString,1}
    valstr::Array{AbstractString,1}

    rownum::Array{AbstractString,1}
    colnum::Array{AbstractString,1}
    valnum::Array{AbstractString,1}
    
    A::SparseOrTranspose
end

function writeas(data::Assoc)
    #Get parts from the assoc
    row = getrow(data)
    col = getcol(data)
    val = getval(data)
    A   = dropzeros!(getadj(data))

    #Split the mapping array into string and number arrays for storage
    rowindex = searchsortedfirst(row,AbstractString,lt=isa)
    colindex = searchsortedfirst(col,AbstractString,lt=isa)
    valindex = searchsortedfirst(val,AbstractString,lt=isa)
    #test if there are string elements in the array
    if (rowindex == 1)
        rowstr = []
    else
        rowstr = chunkstring(join(row[1:(rowindex-1)],del)*del,maxchar)
    end

    if (colindex == 1)
        colstr = []
    else
        colstr = chunkstring(join(col[1:(colindex-1)],del)*del,maxchar)
    end
    
    if (valindex == 1)
        valstr = []
    else
        valstr = chunkstring(join(val[1:(valindex-1)],del)*del,maxchar)
    end
    
    #test if there are number elements in the array.  Note that by serialization all numbers will be converted to float.

    if (rowindex == size(row,1)+1)
        rownum = []
    else
        rownum = chunkstring(join(row[rowindex:end],del)*del,maxchar)
    end

    if (colindex == size(col,1)+1)
        colnum = []
    else
        colnum = chunkstring(join(col[colindex:end],del)*del,maxchar)
    end
    
    if (valindex == size(val,1)+1)
        valnum = []
    else
        valnum = chunkstring(join(val[valindex:end],del)*del,maxchar)
    end


    #Reconstitute converted parts into Serialized

    return AssocSerial(rowstr,colstr,valstr,rownum,colnum,valnum,A)
end

function readas(serData::AssocSerial)
    row = []
    # Last character is delimiter- in case saved with different delimiter
    if !isempty(serData.rowstr)
       row = vcat(row, split(join(serData.rowstr,"")[1:end-1],serData.rowstr[end][end]))
    end
    if !isempty(serData.rownum)
        row = vcat(row, map(float,split(join(serData.rownum,"")[1:end-1],serData.rownum[end][end])))
    end
    row = Array{Union{AbstractString,Number}}(row)

    col = []
    if !isempty(serData.colstr)
       col = vcat(col, split(join(serData.colstr,"")[1:end-1],serData.colstr[end][end]))
    end
    if !isempty(serData.colnum)
        col = vcat(col, map(float,split(join(serData.colnum,"")[1:end-1],serData.colnum[end][end])))
    end
    col = Array{Union{AbstractString,Number}}(col)
    
    val = []
    if !isempty(serData.valstr)
       val = vcat(val, split(join(serData.valstr,"")[1:end-1],serData.valstr[end][end]))
    end
    if !isempty(serData.valnum)
        val = vcat(val, map(float,split(join(serData.valnum,"")[1:end-1],serData.valnum[end][end])))
    end
    val = Array{Union{AbstractString,Number}}(val)
    
    return Assoc(row,col,val,serData.A)
end

function chunkstring(str,chunksize)
    res = []

    idx = 1:chunksize:length(str)

    for i in idx
        res = [res; str[i:min(length(str),i+chunksize-1)]]
    end

    return res
end

function saveassoc(savedir,A::Assoc)
    Awrite = writeas(A)
    @save savedir Awrite
end

function loadassoc(savedir)
    @load savedir Awrite
    return readas(Awrite)
end
