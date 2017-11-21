*** Settings ***
Documentation     This suite test getting the web page from nginx (without istio).
Resource          ${CURDIR}/../libraries/ShellOverSsh.robot
Resource          ${CURDIR}/../libraries/SshCommons.robot
Resource          ${CURDIR}/../libraries/StatefulSetup.robot
Suite Setup       StatefulSetup.Setup_Suite_With_Named_Pod_Types_Single    1    nginx   client
Suite Teardown    StatefulSetup.Teardown_Suite_With_Named_Pod_Types_Single    1    nginx    client

*** Test Cases ***
Pod_To_Nginx_Ping
    [Documentation]    Execute "ping -c 5" from client pod to nginx IP address, check zero packet loss.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    client
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Command    client    ping -c 5 ${nginx_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    client

Host_To_Nginx_Ping
    [Documentation]    Execute "ping -c 5" from host to nginx IP address, check zero packet loss.
    ${stdout} =    SshCommons.Execute_Command_And_Log    ping -c 5 ${nginx_ip}
    BuiltIn.Should_Contain   ${stdout}    5 received, 0% packet loss

Get_Web_Page_From_Pod
    [Documentation]    Execute curl from client pod to nginx IP address, check the expected response is seen.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    client
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Command    client    curl http://${nginx_ip}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    client

Get_Web_Page_From_Host
    [Documentation]    Execute curl from host to nginx IP address, check the expected response is seen.
    ${stdout} =    SshCommons.Execute_Command_And_Log    curl http://${nginx_ip} --noproxy ${nginx_ip}    ignore_stderr=${True}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
