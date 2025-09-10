using SparseArrays

function WriteCSV(A::Assoc, del = ',', eol = '\n')
end

function ReadCSV(iostream::IOBuffer, del = ',', eol = '\n'; quotes = true)
end


# Writing and Reading CSV Files
function WriteCSV(A::Assoc, output::Union{IOStream, String}, del = ',', eol = '\n')
    #Because of potential memory issues, the Assoc will not be converted to dense matrix.
    # Instead the dense form is directly printed onto the file.
    iostream::IOStream
    if typeof(output) == String
       global iostream = open(output,"w")
    end

    #First write column
    for c = 1:size(A.col,1)
        write(iostream,del) #Separator
        print(iostream,A.col[c])
    end
    
    write(iostream,eol)
    
    valMap = !isempty(A.val) && !(A.val ==[1.0]) #Check if val needs to be mapped.
    #For each row write in row
    for r = 1:size(A.row,1)
        print(iostream,A.row[r])
        for c = 1:size(A.col,1)
            write(iostream,del)
            if A.A[r,c] != 0
                if valMap #Mapping needed
                    write(iostream,A.val[A.A[r,c]])
                else #Mappping not needed.
                    print(iostream,A.A[r,c])
                end
            end
        end
        write(iostream,eol)
        flush(iostream) #Clear buffer for each line.
    end
    #Close stream.
    close(iostream)
end

function ReadCSV(input::Union{IOStream, String}, del = ',', eol = '\n'; quotes = true)
    # If input is a String, check if it points to a real file
    if isa(input, String) && isfile(input)
        # It's a filename! Open the file and read
        open(input, "r") do io
            return _readcsv(io, del, eol; quotes=quotes)
        end
    elseif isa(input, IOStream)
        # It's already an open file
        return _readcsv(input, del, eol; quotes=quotes)
    elseif isa(input, String)
        # It's a raw CSV string, parse it directly
        io = IOBuffer(input)
        return _readcsv(io, del, eol; quotes=quotes)
    else
        error("Unsupported input type for ReadCSV: $(typeof(input))")
    end
end

# Internal helper function
function _readcsv(io::IO, del::Char, eol::Char; quotes=true)
    # Example logic to parse lines; replace with your real parser
    lines = readlines(io)
    parsed = [split(line, del) for line in lines]
    return parsed
end

function ReadCSV1(input::Union{IOStream, String}, del = ',', eol = '\n'; quotes = true)

    iostream::IOStream
    inDim::Array{String}
    if typeof(input) == String
        global iostream = open(input,"r")
        if filesize(iostream) <= 1
            return Assoc("","","")
        end
        inDim = readdlm(fname,del,eol, quotes=quotes)
    end

    rowN,colN = size(inDim)
    row = [];
    col = [];
    val = [];
    if colN >=2
        for x = 2:colN
            for y = 2:rowN
                if ~isempty(inDim[y,x])
                    push!(row, inDim[y,1])
                    push!(col, inDim[1,x])
                    push!(val, inDim[y,x])
                end
            end
        end
        return Assoc(string.(row),string.(col),val,(+))
    else #2D associative?
    # TODO implement this special case (currently ignoring, for now)
        return
    end
end

#=
Writing and Reading JLD Files
Assoc Serialized for saving
NOTE: saving would convert row and col types to number.
=#

# Delimiter for saving- using new line is safer than comma!
del = "\n"

struct AssocSerial
    rowstr::AbstractString
    colstr::AbstractString
    valstr::AbstractString

    rownum::AbstractString
    colnum::AbstractString
    valnum::AbstractString
    
    A::SparseMatrixCSC
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
        rowstr = ""
    else
        rowstr = join(row[1:(rowindex-1)],del)*del;#chunkstring(join(row[1:(rowindex-1)],del)*del,maxchar)
    end

    if (colindex == 1)
        colstr = ""
    else
        colstr = join(col[1:(colindex-1)],del)*del;#chunkstring(join(col[1:(colindex-1)],del)*del,maxchar)
    end
    
    if (valindex == 1)
        valstr = ""
    else
        valstr = join(val[1:(valindex-1)],del)*del;#chunkstring(join(val[1:(valindex-1)],del)*del,maxchar)
    end
    
    #test if there are number elements in the array.  Note that by serialization all numbers will be converted to float.

    if (rowindex == size(row,1)+1)
        rownum = ""
    else
        rownum = join(row[rowindex:end],del)#chunkstring(join(row[rowindex:end],del)*del,maxchar)
    end

    if (colindex == size(col,1)+1)
        colnum = ""
    else
        colnum = join(col[colindex:end],del)#chunkstring(join(col[colindex:end],del)*del,maxchar)
    end
    
    if (valindex == size(val,1)+1)
        valnum = ""
    else
        valnum = join(val[valindex:end],del)#chunkstring(join(val[valindex:end],del)*del,maxchar)
    end


    #Reconstitute converted parts into Serialized
    
    return AssocSerial(rowstr,colstr,valstr,rownum,colnum,valnum,A)
end

function readas(serData::AssocSerial)
    row = []
    # Last character is delimiter- in case saved with different delimiter
    if !isempty(serData.rowstr)
       row = vcat(row, split(serData.rowstr[1:end-1],serData.rowstr[end]))#vcat(row, split(join(serData.rowstr,"")[1:end-1],serData.rowstr[end][end]))
    end
    if !isempty(serData.rownum)
        rownums = convert(Array{Number},parse.(Float64,split(serData.rownum,del)))
        rownums[isinteger.(rownums)] = Int.(rownums[isinteger.(rownums)])
        row = vcat(row, rownums)
        #row = vcat(row, parse.(Float64,split(serData.rownum,del)))#vcat(row, map(float,split(join(serData.rownum,"")[1:end-1],serData.rownum[end][end])))
    end
    row = Array{Union{AbstractString,Number}}(row)

    col = []
    if !isempty(serData.colstr)
       col = vcat(col, split(serData.colstr[1:end-1],serData.colstr[end]))#vcat(col, split(join(serData.colstr,"")[1:end-1],serData.colstr[end][end]))
    end
    if !isempty(serData.colnum)
        colnums = convert(Array{Number},parse.(Float64,split(serData.colnum,del)))
        colnums[isinteger.(colnums)] = Int.(colnums[isinteger.(colnums)])
        col = vcat(col, colnums)
        #col = vcat(col, parse.(Float64,split(serData.colnum,del)))#vcat(col, map(float,split(join(serData.colnum,"")[1:end-1],serData.colnum[end][end])))
    end
    col = Array{Union{AbstractString,Number}}(col)
    
    val = []
    if !isempty(serData.valstr)
       val = vcat(val, split(serData.valstr[1:end-1],serData.valstr[end]))#vcat(val, split(join(serData.valstr,"")[1:end-1],serData.valstr[end][end]))
    end
    if !isempty(serData.valnum)
        #val = vcat(val, map(float,split(serData.valnum,del)))#vcat(val, map(float,split(join(serData.valnum,"")[1:end-1],serData.valnum[end][end])))
        valnums = convert(Array{Number},parse.(Float64,split(serData.valnum,del)))
        valnums[isinteger.(valnums)] = Int.(valnums[isinteger.(valnums)])
        val = vcat(val, valnums)
    end
    val = Array{Union{AbstractString,Number}}(val)
    
    return Assoc(row,col,val,serData.A)
end

function readmat(fname)
    
    vars = matread(fname)

    for k in keys(vars)
        if vars[k]["class"] == "Assoc"
            row = convert(Array{Union{AbstractString,Number}},split(vars[k]["row"][1:end-1],vars[k]["row"][end]))
            col = convert(Array{Union{AbstractString,Number}},split(vars[k]["col"][1:end-1],vars[k]["col"][end]))
            if isempty(vars[k]["val"])
                val = convert(Array{Union{AbstractString,Number}},[1.0])
            else
                val = convert(Array{Union{AbstractString,Number}},split(vars[k]["val"][1:end-1],vars[k]["val"][end]))
            end

            vars[k] = Assoc(row,col,val,vars[k]["A"])

            if length(vars) == 1
                return vars[k]
            end

        end
    end

    return vars

end