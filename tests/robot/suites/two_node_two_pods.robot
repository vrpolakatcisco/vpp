*** Settings ***
Documentation     Test suite to test basic ping, udp, tcp and dns functionality of the network plugin in 2 host setup.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       StatefulSetup.Setup_Suite_With_Pod_Set_File    1c1_1s2_1n2
Suite Teardown    StatefulSetup.Teardown_Suite_With_Pod_Set

*** Test Cases ***
Pod_To_Pod_Ping
    [Documentation]    Pod to pod ping, pods are on different nodes.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server    client
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Interactive_Command    client    ping -c 5 ${server_pod_ip}
    BuiltIn.Should_Contain    ${stdout}    5 received, 0% packet loss
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Interactive_Command    server    ping -c 5 ${client_pod_ip}
    BuiltIn.Should_Contain    ${stdout}    5 received, 0% packet loss
    [Teardown]    Teardown_Test_With_Named_Container_Types

Pod_To_Pod_Udp
    [Documentation]    Pod to pod udp, pods are on different nodes.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server    client
    ShellOverSsh.Switch_And_Start_Interactive_Command    server    nc -ul -p 7000
    ShellOverSsh.Switch_And_Start_Interactive_Command    client    nc -u ${server_pod_ip} 7000
    ${text} =    BuiltIn.Set_Variable    Text to be received
    SSHLibrary.Write    ${text}
    ${client_stdout} =    ShellOverSsh.Stop_Interactive_Command_In_Active_Connection
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Interactive_Command    server
    BuiltIn.Should_Contain    ${server_stdout}    ${text}
    [Teardown]    Teardown_Test_With_Named_Container_Types

Pod_To_Pod_Tcp
    [Documentation]    Pod to pod tcp, pods are on different nodes.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server    client
    ${text} =    BuiltIn.Set_Variable    Text to be received
    ShellOverSsh.Switch_And_Start_Interactive_Command    server    nc -l -p 4444
    ShellOverSsh.Switch_And_Execute_Interactive_Command    client    cd; echo "${text}" > some.file
    ShellOverSsh.Start_Interactive_Command_In_Active_Conection    cd; nc ${server_pod_ip} 4444 < some.file
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Interactive_Command    server
    BuiltIn.Should_Contain    ${server_stdout}    ${text}
    ${client_stdout} =    ShellOverSsh.Switch_And_Stop_Interactive_Command    client
    [Teardown]    Teardown_Test_With_Named_Container_Types

Host_To_Pod_Ping
    [Documentation]    Host to pod ping, client_pod_ip is local, server_pod_ip is remote
    # Connection to host_1 is active.
    ${stdout} =    SshCommons.Execute_Command_And_Log    ping -c 5 ${server_pod_ip}
    BuiltIn.Should_Contain    ${stdout}    5 received, 0% packet loss
    ${stdout} =    SshCommons.Execute_Command_And_Log    ping -c 5 ${client_pod_ip}
    BuiltIn.Should_Contain    ${stdout}    5 received, 0% packet loss

Host_To_Pod_Udp_Remote
    [Documentation]    Host to pod udp, dst pod runs on a different nodes.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server
    ShellOverSsh.Switch_And_Start_Interactive_Command    server    nc -ul -p 7000
    ShellOverSsh.Switch_To_Node_And_Start_Interactive_Command    nc -u ${server_pod_ip} 7000
    ${text} =    BuiltIn.Set_Variable    Text to be received
    SSHLibrary.Write    ${text}
    ${client_stdout} =    ShellOverSsh.Stop_Interactive_Command_In_Active_Commenction
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Interactive_Command    server
    BuiltIn.Should_Contain    ${server_stdout}    ${text}
    [Teardown]    Teardown_Test_With_Named_Container_Types

Host_To_Pod_Tcp_Remote
    [Documentation]    Host to pod tcp, dst pod runs on a different nodes.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server
    ShellOverSsh.Switch_And_Start_Interactive_Command    server    nc -l -p 4444
    ${text} =    BuiltIn.Set_Variable    Text to be received
    ShellOverSsh.Switch_To_Node_And_Execute_Command    1    cd; echo "${text}" > some.file
    SshCommons.Execute_Command_And_Log    cd; nc ${server_pod_ip} 4444 < some.file
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Interactive_Command    ssh_session=${server_connection}
    BuiltIn.Should_Contain    ${server_stdout}    ${text}
    ${client_stdout} =    ShellOverSsh.Switch_To_Node_And_Stop_Interactive_Command
    [Teardown]    Teardown_Test_With_Named_Container_Types

Pod_To_Nginx_Local
    [Documentation]    Curl from one pod to another on the same node. Server_pod is just a ubuntu pod running on the same
    ...    same node as nxinf pod.
    [Setup]    Setup_Hosts_Connections
    ${stdout} =    KubernetesEnv.Run_Finite_Command_In_Pod    curl http://${nginx_ip}    ssh_session=${server_connection}
    BuiltIn.Should_Contain    ${stdout}    If you see this page, the nginx web server is successfully installed
    [Teardown]    Teardown_Hosts_Connections

Pod_To_Nginx_Remote
    [Documentation]    Curl from one pod to another. Pods are on different nodes.
    [Setup]    Setup_Hosts_Connections
    ${stdout} =    KubernetesEnv.Run_Finite_Command_In_Pod    curl http://${nginx_ip}    ssh_session=${client_connection}
    BuiltIn.Should_Contain    ${stdout}    If you see this page, the nginx web server is successfully installed
    [Teardown]    Teardown_Hosts_Connections

Host_To_Nginx_Local
    [Documentation]    Curl from linux host pod to another on the same node
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${VM_SSH_ALIAS_PREFIX}2    curl http://${nginx_ip} --noproxy ${nginx_ip}   ignore_stderr=${True}
    BuiltIn.Should_Contain    ${stdout}    If you see this page, the nginx web server is successfully installed

Host_To_Nginx_Remote
    [Documentation]    Curl from linux host to pod on another node
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${VM_SSH_ALIAS_PREFIX}1    curl http://${nginx_ip} --noproxy ${nginx_ip}    ignore_stderr=${True}
    BuiltIn.Should_Contain    ${stdout}    If you see this page, the nginx web server is successfully installed
