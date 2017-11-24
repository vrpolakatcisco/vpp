*** Settings ***
Documentation     Test suite to test ldpreload functionality with iperf.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       Setup
Suite Teardown    StatefulSetup.Teardown_Suite_With_Named_Pod_Types_Single    1    preload_server    preload_client

*** Test Cases ***
# FIXME: Rewrite this from KubeCtl and add test setup/teardown.

Host_To_Pod_Iperf
    [Documentation]    Execute iperf3 command from host, check return code is zero.
    [Timeout]    5 minutes
    SshCommons.Execute_Command_And_Log    ${iperf_cmd}    ignore_stderr=${True}

Pod_To_Pod_Iperf
    [Documentation]    Execute iperf3 comand from client pod towards server pod, checking return code is zero.
    [Timeout]    5 minutes
    ${stdout} =    KubeCtl.Execute_On_Pod    ${testbed_connection}    ${client_pod_name}    iperf3 -V4d -c ${server_ip}    ignore_stderr=${True}

Host_To_Pod_Iperf_Again
    [Documentation]    Execute iperf3 command from host, check return code is zero.
    [Timeout]    5 minutes
    SshCommons.Execute_Command_And_Log    ${iperf_cmd}    ignore_stderr=${True}

Pod_To_Pod_Iperf_Loop
    [Documentation]    Execute multiple iperf3 comands from client pod towards server pod sequentially,
    ...    checking return codes are zero.
    [Timeout]    5 minutes
    BuiltIn.Repeat_Keyword    15    KubeCtl.Execute_On_Pod    ${testbed_connection}    ${client_pod_name}    iperf3 -V4d -c ${server_ip}    ignore_stderr=${True}

*** Keywords ***
Pod_To_Pod_Iperf_Iteration
    [Documentation]    Kubectl exec iperf command in client pod, fail on nonzero return code.
    KubeExec.Execute_In_Container    ${preload_client_pod_name}    ${iperf_cmd}    ignore_stderr=${True}

Setup
    [Documentation]    Call stateful setup and set suite variable for iperf client command.
    StatefulSetup.Setup_Suite_With_Named_Pod_Types_Single    1    preload_server   preload_client
    Builtin.Set_Suite_Variable    \${iperf_cmd}    iperf3 -V4d -c ${preload_server_ip}
