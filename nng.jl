"""
Support for nng library
"""
mutable struct nng_socket
    id::UInt32
end

mutable struct nng_listener
    id::UInt32
end

mutable struct nng_dialer
    id::UInt32
end

function nng_strerror(errno::Int32)
    err = ccall((:nn_strerror, "libnng"), Cstring, (Int32,), errno)
    if err == C_NULL
        error("Error nn_strerror errno: ", errno)
    end
    return unsafe_string(err)
end

function check_err(func_name, rv)
    if rv != 0
        err = nng_strerror(rv)
        error(func_name, err)
    end
end


nng_pull0_open(socket::nng_socket) = ccall((:nng_pull0_open, "libnng"), Int32, (Ref{nng_socket},), socket)
nng_push0_open(socket::nng_socket) = ccall((:nng_push0_open, "libnng"), Int32, (Ref{nng_socket},), socket)
nng_close(socket::nng_socket) = ccall((:nng_close, "libnng"), Int32, (nng_socket,), socket)

function nng_listen(sock::nng_socket, url, lp;  flags=0)
    return ccall((:nng_listen, "libnng"), Cint, (nng_socket, Ptr{UInt8}, Ref{nng_listener}, Cint), sock, url, lp, flags)
end

function nng_dial(socket::nng_socket, url, dp, flags)
    return ccall((:nng_dial, "libnng"), Cint, (nng_socket,  Ptr{UInt8}, Ref{nng_dialer}, Cint), socket, url, dp, flags)
end

function nng_send(socket::nng_socket, msg, flags)
    sz_msg = length(msg)
    bytes = ccall((:nng_send, "libnng"), Int32, (nng_socket, Ptr{UInt8}, Csize_t, Int32), socket, msg, sz_msg, flags)
    return bytes
end

function nng_recv(socket::nng_socket; blocking=false)
    flags = blocking ? 2 : 1 # NNG_FLAG_ALLOC=1 NNG_FLAG_NONBLOCK = 2
    buf = Vector{Ptr{Cchar}}(undef,1)
    sz = Csize_t(0)
    bytes = ccall(
        (:nng_recv, "libnng"),
        Int32,
        (Ref{nng_socket}, Ptr{Cchar}, Ref{Csize_t}, Cint),
        socket, pointer(buf), sz, 1)
    @show bytes
    msg = unsafe_string(buf[1])
    ccall((:nn_freemsg, "libnng"), Cint, (Ptr{Cchar},), buf[1])
    return msg
end

function node0(url)
    sock = nng_socket(0)
    rv = nng_pull0_open(sock)
    check_err("nng_pull0_open", rv)
    lp = nng_listener(0)
    rv = nng_listen(sock, url, lp)
    check_err("nng_listen", rv)
    while true
        msg = nng_recv(sock)
        check_err("nn_recv", msg)
        println("NODE0: RECEIVED ", msg)
    end
end


url = "ipc:///tmp/pipeline.ipc"
#node0(url)
