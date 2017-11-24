*** Settings ***
Documentation     Keywords to perform common tasks for suite or test setup or teardown which manage suite variables.
...
...               The point is to give parametrized keywords which call different named keywords.
...               Guiding rule: Either do not switch from the current active connection, or switch back to master.
...
...               This Resource manages the following suite variables (type ones are actually set elsewhere):
...               \${number_of_nodes} K8s cluster size, usually 2 or 1.
...               \${setup_object} Deserialized JSON holding various data for keywords here to setup or teardown.
...               \${\${type}_pod_name} Detected full name for pod of given type.
...               \${\${type}_\${index}_pod_name} As above but for multireplica pods, index goes from zero.
...               \${\${type}_pod_ip} Detected IP address for pod of given type.
...               \${\${type}_\${index}_pod_ip} As above but for multireplica pods, index goes from zero.
...               \${\${type}_host_ip} Detected IP address for host containing the pod of given type.
...               \${\${type}_\${index}_host_ip} As above but for multireplica pods, index goes from zero.
Resource          ${CURDIR}/all_libs.robot

*** Keywords ***
Get_Host_Ip_By_Location
    [Argument]    ${location}=${EMPTY}
    [Documentation]    Contruct host IP address, defaulting to first node.
    BuiltIn.Log_Many    ${location}
    ${host_index} =    BuiltIn.Set_Variable_If    """${location}""".startswith("node_")    ${location[5:]}    1
    ${host_ip} =    Get_Host_Ip_For_Index    ${host_index}
    BuiltIn.Log    ${host_Ip}
    [Return]    ${host_ip}

Store_Single_Pod_Info
    [Argument]    ${prefix}    ${pod_name}    ${location}=${EMPTY}    ${index}=${EMPTY}
    [Documentation]    Detect info and store it to suite variables.
    BuiltIn.Log_Many    ${prefix}    ${pod_name}    ${location}    ${index}
    ${indexed_prefix} =    Builtin.Set_Variable_If    """${index}"""    ${prefix}_${index}    ${prefix}
    BuiltIn.Set_Suite_Variable    \${${indexed_prefix}_pod_name}    ${pod_name}
    ${pod_details} =     PodManagement.Describe_Pod    ${pod_name}
    ${pod_ip} =     BuiltIn.Evaluate    &{pod_details}[${pod_name}]["IP"]
    BuiltIn.Set_Suite_Variable    \${${indexed_prefix}_pod_ip}    ${pod_ip}
    ${host_ip} =    Get_Host_Ip_By_Location    ${location}
    BuiltIn.Set_Suite_Variable    \${${indexed_prefix}_host_ip}    ${host_ip}

Store_Pods_Info
    [Argument]    ${prefix}    ${pod_names}    ${location}=${EMPTY}
    [Documentation]    Detect whether multiple pods were created, call Store_Single_Pod_Info with or without index.
    Builtin.Log_Many    ${prefix}    ${pod_names}    ${location}
    ${multiplicity} =    Builtin.Get_Length    ${pod_names}
    BuiltIn.Run_Keyword_And_Return_If    ${multiplicity} == 1    Store_Single_Pod_Info    ${prefix}    @{pod_names}[0]    ${location}
    : FOR    ${index}    IN RANGE    ${multiplicity}
    \    ${name} =    Collections.Get_From_List    ${pod_names}    ${index}
    \    Store_Single_Pod_Info    ${prefix}    ${name}    ${location}    ${index}

Deploy_Single_Pod_For_Type
    [Argument]    ${type}
    [Documentation]    Call Deploy_Single_* keyword for type.
    ...    DEPRECATED: Migrate to Setup_Suite_With_Pod_Set
    BuiltIn.Log_Many    ${type}
    ${pod_name} =    BuiltIn.Run_Keyword    NamedPods.Deploy_Single_${type}_And_Verify_Running

Deploy_Multiple_Pod_For_Type
    [Argument]    ${type}    ${multiplicity}
    [Documentation]    Call Deploy_Multiple_* keyword for type.
    ...    DEPRECATED: Migrate to Setup_Suite_With_Pod_Set
    BuiltIn.Log_Many    ${type}    ${multiplicity}
    BuiltIn.Comment    TODO: Unify with _Single_ perhaps accepting single variables will contain number?
    ${pod_names} =    BuiltIn.Run_Keyword    NamedPods.Deploy_Multiple_${type}_And_Verify_Running

Setup_Suite_Common
    [Arguments]    ${nr_nodes}
    [Documentation]    Execute keywords common to multiple setup keywords.
    BuiltIn.Log_Many    ${nr_nodes}
    setup-teardown.Testsuite_Setup
    KubeManagement.Reinit_Kube_Cluster    ${nr_nodes}
    BuiltIn.Set_Suite_Variable    \${number_of_nodes}    ${nr_nodes}

Setup_Suite_With_Pod_Set_Text
    [Arguments]    ${json_text}
    [Documentation]    Run common setup, create pods according to \${json_text}.
    BuiltIn.Log_Many    ${json_text}
    ${setup_object} =    pod_set.from_string    ${json_text}
    BuiltIn.Set_Suite_Variable    \${setup_object}
    ${nr_nodes} =    Colelctions.Get_From_Dictionary    &{object}    nodes
    Setup_Suite_Common    ${nr_nodes}
    TemplatedPods.Deploy_Pod_Set_Object    ${setup_object}

Setup_Suite_With_Pod_Set_File
    [Arguments]    ${file_name}
    [Documentation]    Read contents of the file, proceed with Setup_Suite_With_Pod_Set_Text.
    ${text} =    OperatingSystem.Get_File    ${CURDIR}/../resources/podsets/${file_name}.json
    # Text will be logged in the next line.
    BuiltIn.Run_Keyword_And_Return    Setup_Suite_With_Pod_Set_Text    ${text}

Setup_Suite_With_Named_Pod_Types_Single
    [Arguments]    ${nr_nodes}    @{types}
    [Documentation]    Call parent setup, reinit cluster, deploy pods according to types.
    ...    DEPRECATED: Migrate to Setup_Suite_With_Pod_Set
    BuiltIn.Log_Many    ${nr_nodes}    @{types}
    Setup_Suite_Common    ${nr_nodes}
    # Master connection is active.
    : FOR    ${type}   IN    @{types}
    \    Deploy_Single_And_Store_Name_For_Type    ${type}

Setup_Suite_With_Named_Pod_Types_First_Multiple
    [Arguments]    ${nr_nodes}    ${multiplicity}    ${multiplied_type}    @{other_types}
    [Documentation]    Call parent setup, reinit cluster, deploy pods according to types where only the first is multiple.
    ...    DEPRECATED: Migrate to Setup_Suite_With_Pod_Set
    BuiltIn.Log_Many    ${nr_nodes}    ${multiplicity}    ${multiplied_type}    @{other_types}
    Setup_Suite_Common    ${nr_nodes}
    # Master connection is active.
    Deploy_Multiple_And_Store_Names_For_Type    ${multipied_type}    ${multiplicity}
    : FOR    ${type}   IN    @{other_types}
    \    Deploy_Single_And_Store_Name_For_Type    ${type}

Teardown_Suite_With_Pod_Set
    [Documentation]    Gather logs, use stored object to remove all pods, call parent teardown
    ...    TODO: Do we need to reverse the order?
    NamedPods.Log_Pods_For_Debug    ${number_of_nodes}
    TemplatedPods.Remove_Pod_Set_Object    ${setup_object}
    setup-teardown.Testsuite Teardown

Teardown_Suite_With_Named_Pod_Types
    [Arguments]    @{types}
    [Documentation]    Gather logs, remove created pods in reverse order, call parent teardown.
    ...    This keyword does not care whether the pods were singles or multiples.
    ...    DEPRECATED: Migrate to (setup and) Teardown_Suite_With_Pod_Set
    BuiltIn.Log_Many    ${types}
    NamedPods.Log_Pods_For_Debug    ${number_of_nodes}
    ${reversed_types} =    BuiltIn.Create_List    @{types}
    ${reversed_types} =    Collections.Reverse_List    ${reversed_types}
    : FOR    ${type}    IN    @{reversed_types}
    \    BuiltIn.Run_Keyword    NamedPods.Remove_${type}_And_Verify_Removed
    setup-teardown.Testsuite Teardown

Open_Single_Container_Connection_For_Type
    [Arguments]    ${type}
    [Documentation]    Open new container connection aliased ${type}. Note this switches to the new connection.
    BuiltIn.Log_Many    ${type}
    ${pod_name} =    BuiltIn.Set_Variable    ${${type}_pod_name}
    BuiltIn.Run_Keyword    KubeExec.Open_New_Bash_Container_Connection    ${type}    ${pod_name}    prompt=\#
    Collections.Append_To_List    ${container_aliases}    ${type}

Open_Multiple_Container_Connections_For_Type
    [Arguments]    ${type}    ${multiplicity}
    [Documentation]    Open new container connections aliased \${type}\${index}. Note this switches to the last new connection.
    BuiltIn.Log_Many    ${type}    ${multiplicity}
    : FOR    ${index}    IN RANGE    ${multiplicity}
    \    ${pod_name} =    BuiltIn.Set_Variable    ${${type}_${index}_pod_name}
    \    BuiltIn.Run_Keyword    KubeExec.Open_New_Bash_Container_Connection    ${type}_${index}    ${pod_name}    prompt=\#
    \    Collections.Append_To_List    ${container_aliases}    ${type}_${index}

Open_Container_Connections_For_Other_Types
    [Arguments]    @{other_types}
    [Documentation]    Iterate over \@{other_types}, calling Open_Single_Container_Connection_For_Type.
    BuiltIn.Log_Many    ${other_types}
    : FOR    ${type}   IN    @{other_types}
    \    Open_Single_Container_Connection_For_Type    ${type}

Setup_Test_With_Named_Container_Types_Single
    [Argument]    @{types}
    [Documentation]    Open container connections according to types (no multiples), switch connection back to master node.
    BuiltIn.Log_Many    @{types}
    ${container_aliases} =    BuiltIn.Create_List
    Built_in.Set_Suite_Variable    \${container_aliases}
    Open_Container_Connections_For_Other_Types    @{types}
    [Teardown]    NamedVms.Switch_To_Node_For_Index    1

Setup_Test_With_Named_Container_Types_First_Multiple
    [Argument]    ${multiplicity}    ${multiplied_type}    @{other_types}
    [Documentation]    Open container connections according to types where only the first is multiple,
    ...    switch connection back to master node.
    BuiltIn.Log_Many    ${multiplicity}    ${multiplied_type}    @{other_types}
    ${container_aliases} =    BuiltIn.Create_List
    Built_in.Set_Suite_Variable    \${container_aliases}
    Open_Multiple_Container_Connections_And_Store_Ips_For_Type    ${multiplied_type}    ${multiplicity}
    Open_Container_Connections_For_Other_Types    @{other_types}
    [Teardown]    NamedVms.Switch_To_Node_For_Index    1

Teardown_Test_With_Named_Container_Types
    [Documentation]    Close container connections in reverse order ignoring errors, switch connection back to master node.
    Collections.Reverse_List    ${container_aliases}
    : FOR    ${alias}    IN    @{container_aliases}
    \    SSHLibrary.Switch_Connection    ${alias}
    \    KubeExec.Close_Active_Container_Connection
    [Teardown]    NamedVms.Switch_To_Node_For_Index    1
