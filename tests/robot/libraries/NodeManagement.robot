*** Settings ***
Documentation     This is a library to handle actions related to kubernetes cluster nodes.
...
...               See other libraries for keywords related to VMs, whole cluster, pods or containers.
Resource          ${CURDIR}/all_libs.robot

*** Keywords ***
Kubeadm_Reset
    [Documentation]    Execute "sudo kubeadm reset" on active session.
    BuiltIn.Run_Keyword_And_Return    SshCommons.Execute_Command_And_Log    sudo kubeadm reset

Kubeadm_Init
    [Arguments]    ${arguments}=--token-ttl 0 --skip-preflight-checks
    [Documentation]    Execute "sudo -E kubeadm init" with configurable arguments on active session.
    Builtin.Log_Many    ${arguments}
    BuiltIn.Run_Keyword_And_Return    SshCommons.Execute_Command_And_Log    sudo -E kubeadm init ${arguments}    ignore_stderr=${True}

Check_Cluster_Ready
    [Arguments]     ${nr_nodes}
    [Documentation]    Get nodes, check there are \${nr_nodes}, for each node Verify_Cluster_Node_Ready.
    BuiltIn.Log_Many     ${nr_nodes}
    &{nodes} =    KubeCtl.Get_Nodes
    BuiltIn.Length_Should_Be    ${nodes}    ${nr_nodes}
    ${names} =     Collections.Get_Dictionary_Keys     &{nodes}
    : FOR    ${name}    IN    @{names}
    \    ${status} =    BuiltIn.Evaluate    &{nodes}[${name}]['STATUS']
    \    BuiltIn.Should_Be_Equal    ${status}    Ready

Wait_Until_Cluster_Ready
    [Arguments]    ${nr_nodes}    ${timeout}=180s    ${check_period}=5s
    [Documentation]    WUKS around Check_Cluster_Ready.
    BuiltIn.Log_Many    ${nr_nodes}    ${timeout}    ${check_period}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${check_period}    Verify_Cluster_Ready    ${nr_nodes}

Taint_Active_Node
    [Arguments]    ${cmd_parameters}
    [Documentation]    Execute "kubectl taint" with given \${cmd_parameters}, return the result.
    Builtin.Log_Many    ${cmd_parameters}
    BuiltIn.Run_Keyword_And_Return    SshCommons.Execute_Command_And_Log    kubectl taint ${cmd_parameters}

Label_Node_With_Index
    [Argument]    ${index}
    [Documentation]    Call Label_Nodes with arguments constructed for \${index}.
    ${name} =    NamedVms.Get_Host_Name_For_Index    ${index}
    ${label} =    NamedVms.Get_Host_Label_For_Index    ${index}
    Label_Nodes    ${name}    location    ${label}

Label_Nodes
    [Arguments]    ${node_name}   ${label_key}    ${label_value}
    [Documentation]    Execute "kubectl label nodes" with given parameters, return the result.
    Builtin.Log_Many    ${node_name}   ${label_key}    ${label_value}
    BuiltIn.Run_Keyword_And_Return    SshCommons.Execute_Command_And_Log    kubectl label nodes ${node_name} ${label_key}=${label_value}
