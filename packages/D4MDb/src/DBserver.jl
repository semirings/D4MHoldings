

# A DBserver struct contains the connect information for a database.
struct DBserver
    instanceName::String
    host::String
    user::String
    pass::String
    dbType::String
    Graphulo
end

using JavaCall

# dbsetup calls the DBserver constructor given configuration information.
# When provided only the instance name, dbsetup assumes the default configuration directory.
#   The default location is that on the MIT Supercloud.
#   Assumes existance of two files: accumulo_user_password.txt and dnsname containing password and hostname, respectively.
#   Assumes username is AccumuloUser.
# When provided a directory, will assume configuration files are in that directory.
#   Assumes existance of two files: accumulo_user_password.txt and dnsname containing password and hostname, respectively.
#   Assumes username is AccumuloUser.
# When provided a configuration file, will read in and use the configuration in the file.
#   See example configuration file for formatting.

function dbinit()
    if ~JavaCall.isloaded()
        JavaCall.addClassPath(joinpath(dirname(pathof(D4M)),"..","libext","*"))
        JavaCall.addClassPath(joinpath(dirname(pathof(D4M)),"..","lib","graphulo-3.0.0.jar"))
        JavaCall.init()
    else
        println("JVM already initialized")
    end

    # Check if correct packages are on classpath
    System = @jimport java.lang.System
    cpath = jcall(System, "getProperty", JString, (JString,), "java.class.path")

    if ~occursin("graphulo", cpath)
        println("Required Graphulo libraries for database operations missing from Java classpath.")
        println("To fix, add the required libraries (see Database Use in the readme).")
        println("Then restart Julia, and intialize jvm using dbinit().")
    end
end

function dbsetup(instance::AbstractString, hostname::AbstractString, username::AbstractString, pword::AbstractString)
    # Setup with arguments; insecure but convenient.

    if ~JavaCall.isloaded()
        println("Starting up JVM for DB operations")
        dbinit()
    end

    g = @jimport "edu.mit.ll.graphulo.MatlabGraphulo"
#    Graphulo = g((JString, JString, JString, JString,), instance, hostname, username, pword)
#    DB = DBserver(instance,hostname,username,pword,"BigTableLike",Graphulo)
    DB = DBserver(instance,hostname,username,pword,"BigTableLike")
    return DB
end

function dbsetup(instance, config="/home/gridsan/tools/groups/")
    # Note default value for config location is the MIT Supercloud default location
    if isdir(config) # Config dir
        dbdir = config*"/databases/"*instance
        f = open(dbdir*"/accumulo_user_password.txt","r")
        pword = read(f, String)
        username = "AccumuloUser"
        f = open(dbdir*"/dnsname","r")
        hostname = replace(read(f, String),"\n" => "")*":2181"
    else # Config file
        f = open(config)
        conf = readlines(config)
        conf = Dict(l[1] => l[2] for l in split.(conf,"="))
        instance = conf["instance"]
        hostname = conf["hostname"]
        username = conf["username"]
        pword = conf["password"]
    end

    return dbsetup(instance, hostname, username, pword)
end

# ls returns a list of tables that exist in the DBserver DB.
function ls(DB::DBserver)
    dbInfo = @jimport "edu.mit.ll.d4m.db.cloud.D4mDbInfo"
    dbInfoObj = dbInfo((JString, JString, JString, JString,), DB.instanceName, DB.host, DB.user, DB.pass)
    
    tables = jcall(dbInfoObj, "getTableList", JString, (),)
    
    return split(tables[1:end-1],tables[end])
end

# getindex returns a binding to a table. If the table does it exist, it creates the table.
# A database table struct is returned.
function getindex(DB::DBserver,tableName::String)
    
    ops = @jimport "edu.mit.ll.d4m.db.cloud.D4mDbTableOperations"
    opsObj = ops((JString, JString, JString, JString,), DB.instanceName, DB.host, DB.user, DB.pass)
    
    if ~any(ls(DB) .== tableName) # Create new table if it doesn't exist
        println("Creating "*tableName*" in "*DB.instanceName);
        jcall(opsObj,"createTable", Nothing, (JString,), tableName)
    end
    
    d4mQuery = @jimport "edu.mit.ll.d4m.db.cloud.D4mDataSearch"
    queryObj = d4mQuery((JString, JString, JString, JString, JString,), DB.instanceName, DB.host, tableName, DB.user, DB.pass)
    
    return DBtable(DB, tableName, "", 0, 0, "", 5e5, queryObj,opsObj)
    
end

# getindex returns a binding to a table. If the table does it exist, it creates the table.
# When a second table name is provided, a database table pair is returned.
function getindex(DB::DBserver,tableName1::String,tableName2::String)
    
    ops = @jimport "edu.mit.ll.d4m.db.cloud.D4mDbTableOperations"
    opsObj = ops((JString, JString, JString, JString,), DB.instanceName, DB.host, DB.user, DB.pass)
    
    # Create new tables if they don't exist
    if ~any(ls(DB) .== tableName1) || ~any(ls(DB) .== tableName2)
        if ~any(ls(DB) .== tableName1)
            println("Creating "*tableName1*" in "*DB.instanceName)
            jcall(opsObj,"createTable", Nothing, (JString,), tableName1)
        end
        if ~any(ls(DB) .== tableName2)
            println("Creating "*tableName2*" in "*DB.instanceName)
            jcall(opsObj,"createTable", Nothing, (JString,), tableName2)
        end
    end
    
    d4mQuery = @jimport "edu.mit.ll.d4m.db.cloud.D4mDataSearch"
    queryObj = d4mQuery((JString, JString, JString, JString, JString,), DB.instanceName, DB.host, tableName1, DB.user, DB.pass)
    
    return DBtablePair(DB, tableName1, tableName2, "", 0, 0, "", 5e5, queryObj,opsObj)
    
end

# Returns whether a table with the given name exists in Accumulo
function ispresent(DB::DBserver, tableName1::String)
    return any(ls(DB) .== tableName1)
end

# Deletes a table with the given name.
function deletename(DB::DBserver, name::AbstractString)
    defaultnames = ["accumulo.metadata", "accumulo.replication", "accumulo.root", "trace"]
    if any(defaultnames .== name)
        println("Table with name " * name * " is a default table")
    elseif ispresent(DB, name)
        delete(DB[String(name)])
    else
        println("Table with name " * name * " does not exist in " * DB.instanceName)
    end
end

# Deletes all tables, except for the 4 default ones in the Accumulo database.
function deleteall(DB::DBserver)
    defaultnames = ["accumulo.metadata", "accumulo.replication", "accumulo.root", "trace"]
    for name in ls(DB)
        if ~(any(defaultnames .== name))
            delete(DB[String(name)])
        end
    end
end

# Deletes all tables, withh a given prefix, except for the 4 default ones in the Accumulo database.
function deleteprefix(DB::DBserver, prefix::AbstractString)
    defaultnames = ["accumulo.metadata", "accumulo.replication", "accumulo.root", "trace"]
    for name in ls(DB)
        if ~(any(defaultnames .== name)) && startswith(name, prefix)
                delete(DB[String(name)])
        end
    end
end