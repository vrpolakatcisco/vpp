*** Settings ***
Documentation     Test suite to test basic ping, udp, tcp and dns functionality of the network plugin.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       StatefulSetup.Setup_Suite_With_Named_Pod_Types_Single    1    server   client
Suite Teardown    StatefulSetup.Teardown_Suite_With_Named_Pod_Types_Single    1    server    client

*** Test Cases ***
Pod_To_Pod_Ping
    [Documentation]    Execute "ping -c 5" command between pods (both ways), require no packet loss.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server   client
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Command    client    ping -c 5 ${server_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Command    server    ping -c 5 ${client_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    server    client

Pod_To_Pod_Udp
    [Documentation]    Start UDP server and client, send message, stop both and check the message has been reseived.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server   client
    ShellOverSsh.Switch_And_Start_Command    server    nc -ul -p 7000
    ShellOverSsh.Switch_And_Start_Command    client    nc -u ${server_ip} 7000
    ${text} =    BuiltIn.Set_Variable    Text to be received
    SSHLibrary.Write    ${text}
    # We are already on client session, but switching looks better and is resistant to rewrites.
    ${client_stdout} =    ShellOverSsh.Switch_And_Stop_Command    client
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Command    server
    BuiltIn.Should_Contain   ${server_stdout}    ${text}
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    server    client

Pod_To_Pod_Tcp
    [Documentation]    Start TCP server, start client sending the message, stop server, check message has been received, stop client.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server   client
    ${text} =    BuiltIn.Set_Variable    Text to be received
    ShellOverSsh.Switch_And_Execute_Command    client    cd; echo "${text}" > some.file
    ShellOverSsh.Switch_And_Start_Command    server    nc -l -p 4444
    ShellOverSsh.Switch_And_Start_Command    client    cd; nc ${server_ip} 4444 < some.file
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Command    server
    BuiltIn.Should_Contain   ${server_stdout}    ${text}
    ${client_stdout} =    ShellOverSsh.Switch_And_Stop_Command    client
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    server    client

Host_To_Pod_Ping
    [Documentation]    Execute "ping -c 5" command from host to both pods, require no packet loss.
    ${stdout} =    SshCommons.Execute_Command_And_Log    ping -c 5 ${server_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
    ${stdout} =    SshCommons.Execute_Command_And_Log    ping -c 5 ${client_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss

Host_To_Pod_Udp
    [Documentation]    The same as Pod_To_Pod_Udp but client is on host instead of pod.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server
    ShellOverSsh.Switch_And_Start_Command    server    nc -ul -p 7000
    ShellOverSsh.Switch_To_Index_And_Start_Command    1    nc -u ${server_ip} 7000
    ${text} =    BuiltIn.Set_Variable    Text to be received
    SSHLibrary.Write    ${text}
    ${client_stdout} =    ShellOverSsh.Stop_Command_In_Active_Connection
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Command    server
    BuiltIn.Should_Contain   ${server_stdout}    ${text}
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    server

Host_To_Pod_Tcp
    [Documentation]    The same as Pod_To_Pod_Tcp but client is on host instead of pod.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    server
    ${text} =    BuiltIn.Set_Variable    Text to be received
    SshComons.Execute_Command_And_Log     cd; echo "${text}" > some.file
    ShellOverSsh.Switch_And_Start_Command    server    nc -l -p 4444
    ShellOverSsh.Switch_To_Index_And_Start_Command    1    cd; nc ${server_ip} 4444 < some.file
    ${server_stdout} =    ShellOverSsh.Switch_And_Stop_Command    server
    BuiltIn.Should_Contain   ${server_stdout}    ${text}
    ${client_stdout} =    ShellOverSsh.Switch_To_Index_And_Stop_Command    1
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    server
