*** Settings ***
Documentation     Test suite to test plugin by using ldpreloaded nginx.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       StatefulSetup.Setup_Suite_With_Named_Pod_Types_Single    1    preload_nginx   preload_client
Suite Teardown    StatefulSetup.Teardown_Suite_With_Named_Pod_Types_Single    1    preload_nginx    preload_client

*** Test Cases ***
Pod_To_Nginx
    [Documentation]    Execute curl to nginx IP address from client pod on other host, check the expected response is seen.
    [Setup]    StatefulSetup.Setup_Test_With_Named_Container_Types_Single    preload_client
    ${stdout} =    ShellOverSsh.Switch_And_Execute_Command    client    curl http://${preload_nginx_ip}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
    [Teardown]    StatefulSetup.Teardown_Test_With_Named_Container_Types    preload_client

Host_To_Nginx
    [Documentation]    Execute curl to nginx IP address from the same node, check the expected response is seen.
    ${stdout} =    SshCommons.Execute_Command_And_Log    curl http://${preload_nginx_ip} --noproxy ${preload_nginx_ip}    ignore_stderr=${True}
    BuiltIn.Should_Contain   ${stdout}    If you see this page, the nginx web server is successfully installed
