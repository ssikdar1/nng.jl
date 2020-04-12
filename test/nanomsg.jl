using Test
include("../nanomsg.jl")

# Pipeline example
# NN_PROTO_PIPELINE 5
#define NN_PUSH (NN_PROTO_PIPELINE * 16 + 0)
@test nn_socket(5 * 16 + 0) > -1

@test nn_strerror(22) == "Invalid argument"

# Invalid protocol
@test_throws ErrorException nn_socket(16 * 16 + 0)
