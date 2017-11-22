*** Settings ***
Documentation     Test suite to test basic ping, udp, tcp and dns functionality of the network plugin.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       StatefulSetup.Setup_Suite_With_Named_Pod_Types_First_Multiple    1    10    nginx_10   client
Suite Teardown    StatefulSetup.Teardown_Suite_With_Named_Pod_Types_Single    1    10    nginx_10    client

*** Test Cases ***
Pod_To_Ten_Nginxes
    [Documentation]    Curl from client pod to all nginx pods. Pods might be on different nodes.
    : FOR    ${index}    IN RANGE    10
    \    Client_Pod_To_One_Of_Nginxes    ${index}

Host_To_Ten_Nginxes
    [Documentation]    Curl from master host to all nginx pods. Pods might be on different nodes.
    : FOR    ${index}    IN RANGE    10
    \    Host_To_One_Of_Nginxes    ${index}

*** Keywords ***
Client_Pod_To_One_Of_Nginxes
    [Arguments]    ${index}
    [Documentation]    Based on \${index} (from 0 to 9), issue curl from active connection (client pod)
    ...    to nginx of that index.
    BuiltIn.Log_Many    ${index}
    ${nginx_ip} =    BuiltIn.Set_Variable    ${nginx_10_${index}_ip}
    ${stdout} =    ShellOverSsh.Execute_Command_In_Active_Connection    curl http://${nginx_ip}
    BuiltIn.Should_Contain    ${stdout}    If you see this page, the nginx web server is successfully installed

Host_To_One_Of_Nginxes
    [Arguments]    ${index}
    [Documentation]    Based on \${index} (from 0 to 9), issue curl from host to nginx of that index.
    ${nginx_ip} =    BuiltIn.Set_Variable    ${nginx_10_${index}_ip}
    # TODO: Compute host IPs in StatefulSetup and store them in suite varibles.
    ${host_ip} =    PodManagement.Get_Host_Ip_For_Pod_Name    ${nginx_10_${index}_pod_name}
    ${stdout} =    SshCommons.Execute_Command_And_Log    curl http://${ip} --noproxy ${host_ip}   ignore_stderr=${True}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
