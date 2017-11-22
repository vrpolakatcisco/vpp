*** Settings ***
Documentation     Test suite to test basic ping, udp, tcp and dns functionality of the network plugin in 2 host setup.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       StatefulSetup.Setup_Suite_With_Pod_Set    {"nodes":2,"pod_set":[{"template":"ubuntu","name":"client","replicas":1,"location":"client_node"},{"template":"ubuntu","name":"server","replicas":1,"location":"server_node"},{"template":"nginx","name":"nginx","replicas":1,"location":"server_node"}]}
Suite Teardown    StatefulSetup.Teardown_Suite_With_Pod_Set

*** Test Cases ***
Pod_To_Pod_Ping
    [Documentation]    Pod to pod ping, pods are on different nodes.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    client    server
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Command    client    ping -c 5 ${server_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
#    ${stdout} =    ShellOverSsh.Switch_And_Execute_Command    server    ping -c 5 ${client_ip}
#    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
    [Teardown]    Teardown_Test_With_Named_Container_Types

######
### Rewrite ended here so far.
######

#Pod_To_Pod_Udp
#    [Documentation]    Pod to pod udp, pods are on different nodes.
#    [Setup]    Setup_Hosts_Connections
#    KubernetesEnv.Init_Infinite_Command_in_Pod    nc -ul -p 7000    ssh_session=${server_connection}
#    KubernetesEnv.Init_Infinite_Command_in_Pod    nc -u ${server_ip} 7000    ssh_session=${client_connection}
#    ${text} =    BuiltIn.Set_Variable    Text to be received
#    SSHLibrary.Write    ${text}
#    ${client_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${client_connection}
#    ${server_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${server_connection}
#    BuiltIn.Should_Contain   ${server_stdout}    ${text}
#    [Teardown]    Teardown_Hosts_Connections

#Pod_To_Pod_Tcp
#    [Documentation]    Pod to pod tcp, pods are on different nodes.
#    [Setup]    Setup_Hosts_Connections
#    ${text} =    BuiltIn.Set_Variable    Text to be received
#    KubernetesEnv.Run_Finite_Command_In_Pod    cd; echo "${text}" > some.file    ssh_session=${client_connection}
#    KubernetesEnv.Init_Infinite_Command_in_Pod    nc -l -p 4444    ssh_session=${server_connection}
#    KubernetesEnv.Init_Infinite_Command_in_Pod    cd; nc ${server_ip} 4444 < some.file    ssh_session=${client_connection}
#    ${server_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${server_connection}
#    BuiltIn.Should_Contain   ${server_stdout}    ${text}
#    ${client_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${client_connection}
#    [Teardown]    Teardown_Hosts_Connections

Host_To_Pod_Ping
    [Documentation]    Host to pod ping, client_ip is local, server_ip is remote
    [Setup]    Setup_Hosts_Connections
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${testbed_connection}    ping -c 5 ${server_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${testbed_connection}    ping -c 5 ${client_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
    [Teardown]    Teardown_Hosts_Connections

#Host_To_Pod_Udp_Remote
#    [Documentation]    Host to pod udp, dst pod runs on a different nodes.
#    [Setup]    Setup_Hosts_Connections
#    KubernetesEnv.Init_Infinite_Command_in_Pod    nc -ul -p 7000    ssh_session=${server_connection}
#    KubernetesEnv.Init_Infinite_Command_in_Pod    nc -u ${server_ip} 7000    ssh_session=${testbed_connection}
#    ${text} =    BuiltIn.Set_Variable    Text to be received
#    SSHLibrary.Write    ${text}
#    ${client_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${testbed_connection}    prompt=$
#    ${server_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${server_connection}
#    BuiltIn.Should_Contain   ${server_stdout}    ${text}
#    [Teardown]    Teardown_Hosts_Connections

#Host_To_Pod_Tcp_Remote
#    [Documentation]    Host to pod tcp, dst pod runs on a different nodes.
#    [Setup]    Setup_Hosts_Connections
#    ${text} =    BuiltIn.Set_Variable    Text to be received
#    KubernetesEnv.Run_Finite_Command_In_Pod    cd; echo "${text}" > some.file    ssh_session=${testbed_connection}
#    KubernetesEnv.Init_Infinite_Command_in_Pod    nc -l -p 4444    ssh_session=${server_connection}
#    KubernetesEnv.Init_Infinite_Command_in_Pod    cd; nc ${server_ip} 4444 < some.file    ssh_session=${testbed_connection}
#    ${server_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${server_connection}
#    BuiltIn.Should_Contain   ${server_stdout}    ${text}
#    ${client_stdout} =    KubernetesEnv.Stop_Infinite_Command_In_Pod    ssh_session=${testbed_connection}    prompt=$
#    [Teardown]    Teardown_Hosts_Connections

#Pod_To_Nginx_Local
#    [Documentation]    Curl from one pod to another on the same node. Server_pod is just a ubuntu pod running on the same
#    ...    same node as nxinf pod.
#    [Setup]    Setup_Hosts_Connections
#    ${stdout} =    KubernetesEnv.Run_Finite_Command_In_Pod    curl http://${nginx_ip}    ssh_session=${server_connection}
#    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
#    [Teardown]    Teardown_Hosts_Connections

Pod_To_Nginx_Remote
    [Documentation]    Curl from one pod to another. Pods are on different nodes.
    [Setup]    Setup_Hosts_Connections
    ${stdout} =    KubernetesEnv.Run_Finite_Command_In_Pod    curl http://${nginx_ip}    ssh_session=${client_connection}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
    [Teardown]    Teardown_Hosts_Connections

Host_To_Nginx_Local
    [Documentation]    Curl from linux host pod to another on the same node
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${VM_SSH_ALIAS_PREFIX}2    curl http://${nginx_ip} --noproxy ${nginx_ip}   ignore_stderr=${True}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed

Host_To_Nginx_Remote
    [Documentation]    Curl from linux host to pod on another node
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${VM_SSH_ALIAS_PREFIX}1    curl http://${nginx_ip} --noproxy ${nginx_ip}    ignore_stderr=${True}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
