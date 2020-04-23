"""
Support for nng library
"""
mutable struct nng_socket
    id::UInt32
end

mutable struct nng_listener
    id::UInt32
end

function nng_strerror(errno::Int32)
    err = ccall((:nn_strerror, "libnng.dylib"), Cstring, (Int32,), errno)
    if err == C_NULL
        error("Error nn_strerror errno: ", errno)
    end
    return unsafe_string(err)
end

function check_err(func_name, rv)
    if rv < 0
        err = nn_strerror(rv)
        error(func_name, err)
    end
end


nng_pull0_open(socket::nng_socket) = ccall((:nng_pull0_open, "libnng.dylib"), Int32, (Ref{nng_socket},), socket)  

function nng_listen(sock::nng_socket, url; lp = CNULL, flags=0)
    return ccall((nng_listen, "libnng.dylib"), Cint, (Ref{nng_socket}, Ptr{UInt8}, Ref{nng_listener}, Cint), sock, url, lp, 0)
end

function node0(url)
    socket = nng_socket(0)
    rv = nng_pull0_open(socket)
    check_err(rv) 
    rv = nng_listen(socket, url)
    check_err(rv) 
    while true
        msg = nng_recv(sock, &buf, &sz, NNG_FLAG_ALLOC) 
        check_err("nn_recv", msg)
        println("NODE0: RECEIVED ", msg)
    end 
end

url = "ipc:///tmp/pipeline.ipc"
node0(url)
