*** Settings ***
Documentation     Test suite to test ldpreload functionality with iperf.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       Setup
Suite Teardown    StatefulSetup.Teardown_Suite_With_Named_Pod_Types_Single    1    preload_server    preload_client

*** Test Cases ***
Pod_To_Pod_Iperf
    [Documentation]    Single Pod_To_Pod_Iperf_Iteration.
    Pod_To_Pod_Iperf_Iteration

Pod_To_Pod_Iperf_Loop
    [Documentation]    Multiple Pod_To_Pod_Iperf_Iteration.
    Repeat Keyword    15    Pod_To_Pod_Iperf_Iteration

Host_To_Pod_Iperf
    [Documentation]    Execute iperf3 command from host, check return code is zero.
    SshCommons.Execute_Command_And_Log    ${iperf_cmd}    ignore_stderr=${True}

*** Keywords ***
Pod_To_Pod_Iperf_Iteration
    [Documentation]    Kubectl exec iperf command in client pod, fail on nonzero return code.
    KubeExec.Execute_In_Container    ${preload_client_pod_name}    ${iperf_cmd}    ignore_stderr=${True}

Setup
    [Documentation]    Call stateful setup and set suite variable for iperf client command.
    StatefulSetup.Setup_Suite_With_Named_Pod_Types_Single    1    preload_server   preload_client
    Builtin.Set_Suite_Variable    \${iperf_cmd}    iperf3 -V4d -c ${preload_server_ip}
