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

"""
Unlike with traditional BSD sockets, this function operates asynchronously,
and returns to the caller before the operation is complete.
"""
function nn_connect(sock, addr)
    rv = ccall((:nn_connect, "libnanomsg"), Int32, (Int32, Ptr{UInt8}), sock, addr)
    if rv < 0
        err = nn_strerror(nn_errno())
        error("nn_bind: ", err)
    end
end

function nn_recv(s ; blocking=true)
    # define NN_MSG ((size_t) -1)
    flags = blocking ? 0 : 1 # NN_DONTWAIT=1
    buf = Vector{UInt8}(undef, 8)
    rv = ccall((:nn_recv, "libnanomsg"), Int32, (Int32, Ptr{UInt8}, Csize_t, Int32), s, buf, sizeof(buf), flags)
    #rv = ccall((:nn_recv, "libnanomsg"), Int32, (Int32, Ptr{UInt8}, Csize_t, Int32), s, buf, typemax(Csize_t), flags)

    if rv < 0
        err = nn_strerror(nn_errno())
        error("nn_recv: ", err)
    end
    @show unsafe_string(pointer(buf))
    return buf
end

function nn_send(sock, msg; blocking=true)
    sz_msg = length(msg)
    flags = blocking ? 0 : 1 # NN_DONTWAIT=1
    bytes = ccall((:nn_send, "libnanomsg"), Int32, (Int32, Ptr{UInt8}, Csize_t, Int32), sock, msg, sz_msg, flags)
    if bytes < 0
        err = nn_strerror(nn_errno())
        error("nn_bind: ", err)
    end
    return bytes
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

# TODO having issues with nn_recv

const NN_PROTO_PIPELINE = 5
const NN_PUSH = NN_PROTO_PIPELINE * 16 + 0
const NN_PULL = NN_PROTO_PIPELINE * 16 + 1

function node0()
    url = "ipc:///tmp/pipeline.ipc"
    s = nn_socket(NN_PULL)
    println(s)
    endpoint = nn_bind(s, url)
    while true
        msg = nn_recv(s)
        println("NODE0: RECEIVED ", msg)
    end
end

function node1(url, msg)
    sock = nn_socket(NN_PUSH)
    nn_connect(sock, url)
    nn_send(sock, msg)
end

#node0()
node1("ipc:///tmp/pipeline.ipc", "hello, world its me")
