println("hello world!")

function NNSocket(socket_type; raw=false)
    domain = !raw ? 1 : 2 # AF_SP=1 AF_SP_RAW = 2 
    fd = ccall((:nn_socket, "libnanomsg"), Int32, (Int32, Int32), domain, socket_type)
    if fd < 0
       error("error in creating socket") 
    end
    return fd
end

# Pipeline example
# NN_PROTO_PIPELINE 5
#define NN_PUSH (NN_PROTO_PIPELINE * 16 + 0)
println(NNSocket(5 * 16 + 0))
println(NNSocket(5 * 16 + 0))
println(NNSocket(5 * 16 + 0))
