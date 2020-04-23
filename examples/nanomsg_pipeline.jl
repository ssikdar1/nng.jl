include("../nanomsg.jl")

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
