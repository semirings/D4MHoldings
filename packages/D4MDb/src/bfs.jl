using JavaCall
DBtableTypeorString = Union{DBtableType, AbstractString}

function adjbfs(A::DBtableTypeorString, v0::AbstractString, numsteps::Number, Rtable::AbstractString, RtableTranspose::AbstractString; minDegree = 0::Number, maxDegree = 2^31 - 1::Number, ADegtable = ""::AbstractString, degColumn = ""::AbstractString, degInColQ = false::Bool)


#    (String Atable, String v0, int k, String Rtable, String RtableTranspose,
#    String ADegtable, String degColumn, boolean degInColQ, int minDegree, int maxDegree)

    if isa(A, DBtablePair)
        Aname = A.name1
    elseif isa(A, DBtable)
        Aname = A.name
    else
        Aname = A
    end

    jcall(A.DB.Graphulo, "AdjBFS", JString, 
        (JString, JString, jint, JString, JString, JString, JString, jboolean, jint, jint,), 
        Aname, v0, numsteps, Rtable, RtableTranspose, ADegtable, degColumn, degInColQ, minDegree, maxDegree)

end

# Rows are edges, columns are nodes
function edgebfs(E::DBtableTypeorString, v0::AbstractString, numsteps::Number, Rtable::AbstractString, RtableTranspose::AbstractString; minDegree = 0::Number, maxDegree = 2^31 - 1::Number, EDegtable = ""::AbstractString, degColumn = ""::AbstractString, degInColQ= false::Bool)


    #    (String Atable, String v0, int k, String Rtable, String RtableTranspose,
    #    String ADegtable, String degColumn, boolean degInColQ, int minDegree, int maxDegree)
    
    if isa(E, DBtablePair)
        Ename = E.name1
    elseif isa(E, DBtable)
        Ename = E.name
    else
        Ename = E
    end
    
    JAuthorizations = @jimport "org.apache.accumulo.core.security.Authorizations"
    emptyAuth = JAuthorizations((), )
    JIteratorSetting = @jimport "org.apache.accumulo.core.client.IteratorSetting"
    emptyIteratorSetting = JIteratorSetting((jint, JString, JString), 500, "c", "cname")
    # We want to pass a null IteratorSetting as an argument; JavaCall hates this
    # here's a workaround: 
    emptyIteratorSetting.ptr = C_NULL
    JMutableLong = @jimport "org.apache.commons.lang.mutable.MutableLong"
    emptyMutableLong = JMutableLong((), )

    startPrefixes = ","
    endPrefixes = ","
    plusOp = emptyIteratorSetting
    EScanIteratorPriority = -1
    Eauthorizations = emptyAuth
    EDegauthorizations = emptyAuth
    newVisibility = "" # TODO use null or empty string as default?
    useNewTimestamp = true
    outputUnion = true
    numEntriesWritten = emptyMutableLong

    #=
    JString, JString, jint, JString, JString, JString, JString, JString, JString, jboolean, jint, jint, IteratorSetting, jint,
    Authorizations, Authorizations, JString, jboolean, jboolean, MutableLong

    Etable, v0, k, Rtable, RTtable, startPrefixes, endPrefixes, ETDegtable, degColumn, degInColQ, minDegree, 
    maxDegree, plusOp, EScanIteratorPriority, Eauthorizations, EDegauthorizations, newVisibility, useNewTimestamp, outputUnion, numEntriesWritten
    =#
    
    return jcall(A.DB.Graphulo, "EdgeBFS", JString, 
            (JString, JString, jint, JString, JString, 
                JString, JString, JString, JString, 
                jboolean, jint, jint, JIteratorSetting, 
                jint, JAuthorizations, JAuthorizations, 
                JString, jboolean, jboolean, JMutableLong,), 
            Ename, v0, numsteps, Rtable, RtableTranspose, 
            startPrefixes, endPrefixes, EDegtable, degColumn, 
            degInColQ, minDegree, maxDegree, plusOp, 
            EScanIteratorPriority, Eauthorizations, EDegauthorizations, 
            newVisibility, useNewTimestamp, outputUnion, numEntriesWritten)
    
end
    
function singlebfs(A::DBtableType, v0::AbstractString, numsteps::Number, Rtable = ""::AbstractString, RtableTranspose = ""::AbstractString; minDegree = 0::Number, maxDegree = 2^31 - 1::Number, ADegtable = ""::AbstractString, degColumn = ""::AbstractString, degInColQ = false)


    #    (String Atable, String v0, int k, String Rtable, String RtableTranspose,
    #    String ADegtable, String degColumn, boolean degInColQ, int minDegree, int maxDegree)
    
    if isa(A, DBtablePair)
        Atable = A.name1
    else
        Atable = A.name
    end
    
    return jcall(A.DB.Graphulo, "AdjBFS", JString, 
            (JString, JString, jint, JString, JString, JString, JString, jboolean, jint, jint,), 
            Atable, v0, numsteps, Rtable, RtableTranspose, ADegtable, degColumn, degInColQ, minDegree, maxDegree)
    
end 
