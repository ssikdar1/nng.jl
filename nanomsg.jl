"""
Support for nanomsg library
"""

function nn_strerror(errno::Int32)
    err = ccall((:nn_strerror, "libnanomsg"), Cstring, (Int32,), errno)
    if err == C_NULL
        error("Error nn_strerror errno: ", errno)
    end
    return unsafe_string(err)
end
nn_strerror(errno::Int64) = nn_strerror(Int32(errno))

function nn_errno()
    return ccall((:nn_errno, "libnanomsg"), Int32, ())
end

"""
    NNSocket(protocol; raw=false)

Create an SP socket of type `protocol`.

* `raw`: Set to true to omit end-to-end functionality during creation.
  Used to implement intermediary devices in SP topologies. (default: `false`)
"""
function nn_socket(protocol; raw=false)
    domain = !raw ? 1 : 2 # AF_SP=1 AF_SP_RAW = 2
    fd = ccall((:nn_socket, "libnanomsg"), Int32, (Int32, Int32), domain, protocol)
    if fd < 0
        err = nn_strerror(nn_errno())
        error("nn_socket: ", err)
    end
    return fd
end

"""
    nn_bind(s, addr)

Bind local endpoint to socket s.

Returns positive endpoint ID, else -1 for failure.
"""
function nn_bind(s, addr)
    rv = ccall((:nn_bind, "libnanomsg"), Int32, (Int32, Ptr{UInt8}), s, addr)
    if rv < 0
        err = nn_strerror(nn_errno())
        error("nn_bind: ", err)
    end
    return s
end

function nn_recv(s ; blocking=true)
    flags = blocking ? 0 : 1 # NN_DONTWAIT=1
    msg = Vector{UInt8}(undef, sizeof(Csize_t))
    rv = ccall((:nn_recv, "libnanomsg"), Int32, (Int32, Ptr{UInt8}, Csize_t, Int32), s, msg, sizeof(msg), flags)
    if rv < 0
        err = nn_strerror(nn_errno())
        error("nn_recv: ", err)
    end
    return unsafe_string(pointer(msg))
end

function nn_shutdown(s, endpoint_id)
    rv = ccall((:nn_shutdown, "libnanomsg"), Int32, (Int32, Int32), s, endpoint_id)
    if rv < 0
        err = nn_strerror(nn_errno())
        error("nn_shutdown:", err)
    end
    return rv
end

# Pipeline example

function node0()
    url = "ipc:///tmp/pipeline.ipc"
    # NN_PROTO_PIPELINE 5
    #define NN_PULL (NN_PROTO_PIPELINE * 16 + 1)
    s = nn_socket(5 * 16 + 1)
    println(s)
    endpoint = nn_bind(s, url)
    while true
        msg = nn_recv(s)
        println("NODE0: RECEIVED", msg)
    end
end

node0()
