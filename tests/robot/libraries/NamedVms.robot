*** Settings ***
Documentation     Keywords for accessing specific VMs defined in Variables.
...
...               TODO: Do a better split on ssh- and host- related keywords?
Resource          ${CURDIR}/all_libs.robot

*** Variables ***
${VM_SSH_ALIAS_PREFIX}     vm_

*** Keywords ***
Get_Cluster_Max_Size
    [Documentation]    Log and return number of VMs for this environment.
    ...    Most actions are limited to smaller cluster via \${nr_nodes} or similar,
    ...    but some actions are run on all present available hosts for safety reasons.
    ...    This return number of possibly available hosts.
    ${size} =    Builtin.Set_Variable    ${KUBE_CLUSTER_${CLUSTER_ID}_NODES}
    Builtin.Log    ${size}
    [Return]    ${size}

Get_Host_Alias_For_Index
    [Arguments]    ${index}
    [Documentation]    Construct alias name, log and return it.
    BuiltIn.Log_Many    ${index}
    ${alias} =    BuiltIn.Set_Variable    ${VM_SSH_ALIAS_PREFIX}${index}
    BuiltIn.Log    ${alias}
    [Return]    ${alias}

Get_Host_Ip_For_Index
    [Arguments]    ${index}
    [Documentation]    Construct host IP address value, log and return it.
    BuiltIn.Log_Many    ${index}
    ${ip} =    BuiltIn.Set_Variable    ${KUBE_CLUSTER_${CLUSTER_ID}_VM_${index}_PUBLIC_IP}
    BuiltIn.Log    ${ip}
    [Return]    ${ip}

Get_Host_Name_For_Index
    [Arguments]    ${index}
    [Documentation]    Construct host name value, log and return it.
    BuiltIn.Log_Many    ${index}
    ${name} =    BuiltIn.Set_Variable    ${KUBE_CLUSTER_${CLUSTER_ID}_VM_${index}_HOST_NAME}
    BuiltIn.Log    ${name}
    [Return]    ${name}

Get_Host_Label_For_Index
    [Arguments]    ${index}
    [Documentation]    Construct host label value, log and return it. Currently hardcoded (instead of read from variables).
    BuiltIn.Log_Many    ${index}
    ${label} =    BuiltIn.Set_Variable    host_${index}
    BuiltIn.Log    ${label}
    [Return]    ${label}

Get_Host_User_For_Index
    [Arguments]    ${index}
    [Documentation]    Construct host user name value, log and return it.
    BuiltIn.Log_Many    ${index}
    ${user} =    BuiltIn.Set_Variable    ${KUBE_CLUSTER_${CLUSTER_ID}_VM_${index}_USER}
    BuiltIn.Log    ${user}
    [Return]    ${user}

Get_Host_Passwd_For_Index
    [Arguments]    ${index}
    [Documentation]    Construct host password value, log and return it.
    BuiltIn.Log_Many    ${index}
    ${passwd} =    BuiltIn.Set_Variable    ${KUBE_CLUSTER_${CLUSTER_ID}_VM_${index}_PSWD}
    BuiltIn.Log    ${passwd}
    [Return]    ${passwd}

Get_Host_Role_For_Index
    [Arguments]    ${index}
    [Documentation]    Construct host role value, log and return it.
    BuiltIn.Log_Many    ${index}
    ${role} =    BuiltIn.Set_Variable    ${KUBE_CLUSTER_${CLUSTER_ID}_VM_${index}_ROLE}
    BuiltIn.Log    ${role}
    [Return]    ${role}

Get_Host_Docker
    [Documentation]    Contruct host docker command value, log and return it.
    ${docker} =    BuiltIn.Set_Variable    ${KUBE_CLUSTER_${CLUSTER_ID}_DOCKER_COMMAND}
    BuiltIn.Log    ${docker}
    [Return]   ${docker}

Switch_To_Node_For_Index
    [Arguments]    ${index}
    [Documentation]    Get alias for the index, switch there, return the alias.
    ${alias} =    Get_Host_Alias_For_Index    ${index}
    SSHLibrary.Switch_Connection    ${alias}

Create_Connections_To_Kube_Cluster
    [Documentation]    Create connection and log machine status for each node.
    ...    Leave active connection pointing to the first node (master).
    : FOR    ${index}    IN RANGE    ${KUBE_CLUSTER_${CLUSTER_ID}_NODES}    0    -1
    \    ${alias} =    Get_Host_Alias_For_Index    ${index}
    \    ${ip} =    Get_Host_Ip_For_Index    ${index}
    \    ${user} =    Get_Host_User_For_Index    ${index}
    \    ${passwd} =    Get_Host_Passwd_For_Index    ${index}
    \    SshCommons.Open_Ssh_Connection    ${alias}    ${ip}    ${user}    ${passwd}
    \    Get_Machine_Status    ${alias}

Get_Machine_Status
    [Arguments]    ${alias}
    [Documentation]    Execute df, free, ifconfig -a, ps -aux... on \${machine}, assuming ssh connection there is active.
    BuiltIn.Log_Many    ${machine}
    SshCommons.Execute_Command_And_Log    whoami
    SshCommons.Execute_Command_And_Log    pwd
    SshCommons.Execute_Command_And_Log    df
    SshCommons.Execute_Command_And_Log    free
    SshCommons.Execute_Command_And_Log    ifconfig -a
    SshCommons.Execute_Command_And_Log    ps aux
    SshCommons.Execute_Command_And_Log    export
    SshCommons.Execute_Command_And_Log    docker images
    SshCommons.Execute_Command_And_Log    docker ps -as
    ${master} =    Get_Host_Alias_For_Index    1
    BuiltIn.Return_From_Keyword_If    """${alias}""" != """${master}"""
    SshCommons.Execute_Command_And_Log    kubectl get nodes    ignore_stderr=True    ignore_rc=True
    SshCommons.Execute_Command_And_Log    kubectl get pods    ignore_stderr=True    ignore_rc=True

For_Each_Machine_Switch_And_Call
    [Arguments]    ${nr_nodes}    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Iterating over indices down from \${nr_nodes} switch connection and call \${keyword}.
    BuiltIn.Log_Many    ${nr_nodes}    ${keyword}    ${args}    ${kwargs}
    # TODO: Return list of returned values?
    : FOR    ${index}    IN RANGE    ${nr_nodes}    0    -1
    \    Switch_To_Node_For_Index    ${index}
    \    BuiltIn.Run_Keyword    ${keyword}    @{args}    &{kwargs}

For_Each_Machine_Switch_And_Call_With_Alias
    [Arguments]    ${nr_nodes}    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Iterating over indices down from \${nr_nodes}, construct alias name, switch connection,
    ...    call \${keyword} with the alias as its first positional argument.
    BuiltIn.Log_Many    ${nr_nodes}    ${keyword}    ${args}    ${kwargs}
    : FOR    ${index}    IN RANGE    ${max_index}    0    -1
    \    ${alias} =    Switch_To_Node_For_Index    ${index}
    \    BuiltIn.Run_Keyword    ${keyword}    ${alias}    @{args}    &{kwargs}

For_Each_Machine_Switch_And_Call_With_Index
    [Arguments]    ${nr_nodex}    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Iterating over indices down from \${nr_nodes}, switch connection,
    ...    call \${keyword} with the index as its first positional argument.
    BuiltIn.Log_Many    ${nr_nodes}    ${keyword}    ${args}    ${kwargs}
    : FOR    ${index}    IN RANGE    ${nr_nodes}    0    -1
    \    Switch_To_Node_For_Index    ${index}
    \    BuiltIn.Run_Keyword    ${keyword}    ${index}    @{args}    &{kwargs}

For_Each_Machine_Call_With_Index_Without_Switch
    [Arguments]    ${nr_nodes}    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Iterating over indices down from \${nr_nodes}, call \${keyword} with the index
    ...    as its first positional argument.
    BuiltIn.Log_Many    ${nr_nodes}    ${keyword}    ${args}    ${kwargs}
    : FOR    ${index}    IN RANGE    ${nr_nodes}    0    -1
    \    BuiltIn.Run_Keyword    ${keyword}    ${index}    @{args}    &{kwargs}

Log_All_Ssh_Outputs
    [Documentation]    For each machine, activate its SSH session and call Log_Machine_Output.
    [Timeout]    120s
    For_Each_Machine_Switch_And_Call_With_Alias    Log_Machine_Output

Log_Machine_Output
    [Arguments]    ${alias}
    [Documentation]    On active SSH connection, Read with delay of ${SSH_READ_DELAY}, log and append to log file.
    BuiltIn.Log_Many    ${alias}
    ${output} =    SSHLibrary.Read    delay=${SSH_READ_DELAY}s
    BuiltIn.Log    ${output}
    # TODO: Appending to machine log could be done by a separate reusable keyword.
    OperatingSystem.Append_To_File    ${RESULTS_FOLDER}/output_${alias}.log    ${output}
