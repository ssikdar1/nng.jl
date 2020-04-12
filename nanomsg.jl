
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

# Pipeline example
# NN_PROTO_PIPELINE 5
#define NN_PUSH (NN_PROTO_PIPELINE * 16 + 0)
println(nn_socket(5 * 16 + 0))
println(nn_socket(5 * 16 + 0))
println(nn_socket(5 * 16 + 0))

# test error
#println(nn_socket(16 * 16 + 0))
