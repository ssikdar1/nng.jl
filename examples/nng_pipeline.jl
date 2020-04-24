include("../nng.jl")

function node1(url, msg)
    sock = nng_socket(0)
    rv = nng_push0_open(sock)
    check_err("nng_push0_open", rv)
    dp = nng_dialer(0)
    rv = nng_dial(sock, url, dp, 0) 
    check_err("nng_dial", rv)
    println("NODE1: SENDING ", msg)
    rv = nng_send(sock, msg, 0)
    sleep(1)
    nng_close(sock)
end

node1(url, "HelloWorld")
