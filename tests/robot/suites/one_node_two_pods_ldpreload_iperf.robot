*** Settings ***
Documentation     Test suite to test ldpreload functionality with iperf.
Resource          ${CURDIR}/../libraries/SshCommons.robot
Resource          ${CURDIR}/../libraries/StatefulSetup.robot
Suite Setup       StatefulSetup.Setup_Suite_With_Named_Pod_Types_Single    1    preload_server   preload_client
Suite Teardown    StatefulSetup.Teardown_Suite_With_Named_Pod_Types_Single    1    preload_server    preload_client

*** Test Cases ***
Host_To_Pod_Iperf
    [Documentation]    Execute iperf3 command from host, check return code is zero.
    SshCommons.Execute_Command_And_Log    iperf3 -V4d -c ${preload_server_ip}    ignore_stderr=${True}

Pod_To_Pod_Iperf
    [Documentation]    Single Pod_To_Pod_Iperf_Iteration.
    Pod_To_Pod_Iperf_Iteration

Pod_To_Pod_Iperf_Loop
    [Documentation]    Double Pod_To_Pod_Iperf_Iteration.
    Repeat Keyword    2    Pod_To_Pod_Iperf_Iteration

*** Keywords ***
Pod_To_Pod_Iperf_Iteration
    [Documentation]    Kubectl exec iperf command in client pod, fail on nonzero return code.
    SshCommons.Execute_Command_And_Log    kubectl exec ${preload_client_pod_name} -- iperf3 -V4d -c ${preload_server_ip}    ignore_stderr=${True}
