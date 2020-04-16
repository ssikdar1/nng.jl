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

nn_errno() = ccall((:nn_errno, "libnanomsg"), Int32, ())

function check_err(func_name, rv)
    if rv < 0
        err = nn_strerror(nn_errno())
        error(func_name, err)
    end
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
    return fd
end



"""
    nn_bind(s, addr)

Bind local endpoint to socket s.

Returns positive endpoint ID, else -1 for failure.
"""
nn_bind(s, addr) = ccall((:nn_bind, "libnanomsg"), Int32, (Int32, Ptr{UInt8}), s, addr)

"""
Unlike with traditional BSD sockets, this function operates asynchronously,
and returns to the caller before the operation is complete.

Returns positive endpoint ID, else -1 for failure.
"""
nn_connect(sock, addr) = ccall((:nn_connect, "libnanomsg"), Int32, (Int32, Ptr{UInt8}), sock, addr)

function nn_recv(s ; blocking=true)
    # define NN_MSG ((size_t) -1)
    flags = blocking ? 0 : 1 # NN_DONTWAIT=1
    buf = Vector{Ptr{Cchar}}(undef,1)
    bytes = ccall(
        (:nn_recv, "libnanomsg"),
        Int32,
        (Cint, Ptr{Cchar}, Csize_t, Cint),
        s, pointer(buf), typemax(Csize_t), flags)
    msg = unsafe_string(buf[1])
    ccall((:nn_freemsg, "libnanomsg"), Cint, (Ptr{Cchar},), buf[1])
    return msg
end

function nn_send(sock, msg; blocking=true)
    sz_msg = length(msg)
    flags = blocking ? 0 : 1 # NN_DONTWAIT=1
    bytes = ccall((:nn_send, "libnanomsg"), Int32, (Int32, Ptr{UInt8}, Csize_t, Int32), sock, msg, sz_msg, flags)
    return bytes
end

nn_shutdown(s, endpoint_id) = ccall((:nn_shutdown, "libnanomsg"), Int32, (Int32, Int32), s, endpoint_id)

# Pipeline example

const NN_PROTO_PIPELINE = 5
const NN_PUSH = NN_PROTO_PIPELINE * 16 + 0
const NN_PULL = NN_PROTO_PIPELINE * 16 + 1

function node0(url)
    sock = nn_socket(NN_PULL)
    check_err("nn_socket", sock)
    endpoint = nn_bind(s, url)
    check_err("nn_bind", endpoint)
    while true
        msg = nn_recv(s)
        check_err("nn_recv", msg)
        println("NODE0: RECEIVED ", msg)
    end
end

function node1(url, msg)
    sock = nn_socket(NN_PUSH)
    check_err("nn_socket", sock)
    rv = nn_connect(sock, url)
    check_err("nn_connect", rv)
    bytes = nn_send(sock, msg)
    check_err("nn_send", bytes)
    sleep(1) #  wait for messages to flush before shutting down
    rv = nn_shutdown(s, 0)
    check_err("nn_shutdown", rv)
end

node0("ipc:///tmp/pipeline.ipc")
node1("ipc:///tmp/pipeline.ipc", "hello, world its me")
