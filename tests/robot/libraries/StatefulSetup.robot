*** Settings ***
Documentation     Keywords to perform common tasks for suite or test setup or teardown which manage suite variables.
...
...               The point is to give parametrized keywords which call different named keywords.
...               Guiding rule: Either do not switch from the current active connection, or switch back to master.
Resource          ${CURDIR}/all_libs.robot

*** Keywords ***
Deploy_Single_And_Store_Name_For_Type
    [Argument]    ${type}
    [Documentation]    Call Deploy_Single_* keyword for type, store the returned pod name in a suite variable.
    BuiltIn.Log_Many    ${type}
    ${pod_name} =    BuiltIn.Run_Keyword    NamedPods.Deploy_Single_${type}_And_Verify_Running
    BuiltIn.Set_Suite_Variable    \${${type}_pod_name}    ${pod_name}

Deploy_Multiple_And_Store_Names_For_Type
    [Argument]    ${type}    ${multiplicity}
    [Documentation]    Call Deploy_Multiple_* keyword for type, store each returned pod name in a suite variable.
    BuiltIn.Log_Many    ${type}    ${multiplicity}
    BuiltIn.Comment    TODO: Unify with _Single_ perhaps accepting single aliases will contain number?
    ${pod_names} =    BuiltIn.Run_Keyword    NamedPods.Deploy_Multiple_${type}_And_Verify_Running
    : FOR    ${index}    IN RANGE    ${multiplicity}
    \    ${name} =    Colections.Get_From_List    ${pod_names}    ${index}
    \    BuiltIn.Set_Suite_Variable    \${${type}_${index}_pod_name}    ${name}

Setup_Suite_With_Named_Pod_Types_Single
    [Arguments]    ${nr_nodes}    @{types}
    [Documentation]    Call parent setup, reinit cluster, deploy pods according to types.
    BuiltIn.Log_Many    ${nr_nodes}    @{types}
    setup-teardown.Testsuite_Setup
    KubeManagement.Reinit_Kube_Cluster    ${nr_nodes}
    # Master connection is active.
    : FOR    ${type}   IN    @{types}
    \    Deploy_Single_And_Store_Name_For_Type    ${type}

Setup_Suite_With_Named_Pod_Types_First_Multiple
    [Arguments]    ${nr_nodes}    ${multiplicity}    ${multiplied_type}    @{other_types}
    [Documentation]    Call parent setup, reinit cluster, deploy pods according to types where only the first is multiple.
    BuiltIn.Log_Many    ${nr_nodes}    ${multiplicity}    ${multiplied_type}    @{other_types}
    setup-teardown.Testsuite_Setup
    KubeManagement.Reinit_Kube_Cluster    ${nr_nodes}
    # Master connection is active.
    Deploy_Multiple_And_Store_Names_For_Type    ${multipied_type}    ${multiplicity}
    : FOR    ${type}   IN    @{other_types}
    \    Deploy_Single_And_Store_Name_For_Type    ${type}

Teardown_Suite_With_Named_Pod_Types
    [Arguments]    ${nr_nodes}    @{types}
    [Documentation]    Gather logs, remove created pods in reverse order, call parent teardown.
    ...    This keyword does not care whether the pods were singles or multiples.
    BuiltIn.Log_Many    ${nr_nodes}    @{types}
    NamedPods.Log_Pods_For_Debug    ${nr_nodes}
    ${reversed_types} =    BuiltIn.Create_List    @{types}
    ${reversed_types} =    Collections.Reverse_List    ${reversed_types}
    : FOR    ${type}    IN    @{reversed_types}
    \    BuiltIn.Run_Keyword    NamedPods.Remove_${type}_And_Verify_Removed
    setup-teardown.Testsuite Teardown

Open_Single_Container_Connection_And_Store_Ip_For_Type
    [Arguments]    ${type}
    [Documentation]    Open new container connection aliased ${type}, store its IP address in a suite variable.
    ...    Note this switches to the new connection.
    BuiltIn.Log_Many    ${type}
    ${pod_name} =    BuiltIn.Set_Variable    ${${type}_pod_name}
    BuiltIn.Run_Keyword    KubeExec.Open_New_Bash_Container_Connection    ${type}    ${pod_name}    prompt=\#
    ${pod_details} =     PodManagement.Describe_Pod    ${pod_name}
    ${ip} =     BuiltIn.Evaluate    &{pod_details}[${pod_name}]["IP"]
    BuiltIn.Set_Suite_Variable    \${${type}_ip}    ${ip}

Open_Multiple_Container_Connections_And_Store_Ips_For_Type
    [Arguments]    ${type}    ${multiplicity}
    [Documentation]    Open new container connections aliased \${type}\${index},
    ...    store their IP address in suite variables. Note this switches to the last new connection.
    BuiltIn.Log_Many    ${type}    ${multiplicity}
    : FOR    ${index}    IN RANGE    ${multiplicity}
    \    ${pod_name} =    BuiltIn.Set_Variable    ${${type}_${index}_pod_name}
    \    BuiltIn.Run_Keyword    KubeExec.Open_New_Bash_Container_Connection    ${type}_${index}    ${pod_name}    prompt=\#
    \    ${pod_details} =     PodManagement.Describe_Pod    ${pod_name}
    \    ${ip} =     BuiltIn.Evaluate    &{pod_details}[${pod_name}]["IP"]
    \    BuiltIn.Set_Suite_Variable    \${${type}_${index}_ip}    ${ip}

Setup_Test_With_Named_Container_Types_Single
    [Argument]    @{types}
    [Documentation]    Open container connections according to types (no multiples), switch connection back to master node.
    BuiltIn.Log_Many    @{types}
    : FOR    ${type}   IN    @{types}
    \    Open_Single_Container_Connection_And_Store_Ip_For_Types    ${type}
    [Teardown]    NamedVms.Switch_To_Node_For_Index    1

Setup_Test_With_Named_Container_Types_First_Multiple
    [Argument]    ${multiplicity}    ${multiplied_type}    @{other_types}
    [Documentation]    Open container connections according to types where only the first is multiple,
    ...    switch connection back to master node.
    BuiltIn.Log_Many    ${multiplicity}    ${multiplied_type}    @{other_types}
    Open_Multiple_Container_Connections_And_Store_Ips_For_Type    ${multiplied_type}    ${multiplicity}
    : FOR    ${type}   IN    @{other_types}
    \    Open_Single_Container_Connection_And_Store_Ip_For_Types    ${type}
    [Teardown]    NamedVms.Switch_To_Node_For_Index    1

Close_Single_Container_Connection_For_Type
    [Argument]    ${type}
    [Documentation]    Switch to and close the container connection for the type. This leaves no connection active.
    BuiltIn.Log_Many    ${type}
    SSHLibrary.Switch_Connection    ${type}
    KubeExec.Close_Active_Container_Connection

Close_Multiple_Container_Connection_For_Type
    [Argument]    ${type}    ${multiplicity}
    [Documentation]    Switch to and close the container connections for the type. This leaves no connection active.
    BuiltIn.Log_Many    ${type}
    : FOR    ${index}    IN RANGE    ${multiplicity}
    \    SSHLibrary.Switch_Connection    ${type}_${index}
    \    KubeExec.Close_Active_Container_Connection

Teardown_Test_With_Named_Container_Types_Single
    [Argument]    @{types}
    [Documentation]    Close container connections in reverse order ignoring errors, switch connection back to master node.
    BuiltIn.Log_Many    @{types}
    ${reversed_types} =    BuiltIn.Create_List    @{types}
    ${reversed_types} =    Collections.Reverse_List    ${reversed_types}
    : FOR    ${type}    IN    @{reversed_types}
    \    BuiltIn.Run_Keyword_And_Ignore_Error    Close_Container_Connection_For_Type    ${type}
    [Teardown]    NamedVms.Switch_To_Node_For_Index    1

Teardown_Test_With_Named_Container_Types_First_Multiple
    [Argument]    ${multiplicity}    ${multiplied_type}    @{other_types}
    [Documentation]    Close container connections in reverse order ignoring errors, switch connection back to master node.
    BuiltIn.Log_Many    ${multiplicity}    ${multiplied_type}    @{other_types}
    ${reversed_types} =    BuiltIn.Create_List    @{other_types}
    ${reversed_types} =    Collections.Reverse_List    ${reversed_types}
    : FOR    ${type}    IN    @{reversed_types}
    \    BuiltIn.Run_Keyword_And_Ignore_Error    Close_Container_Connection_For_Type    ${type}
    BuiltIn.Run_Keyword_And_Ignore_Error    Close_Multiple_Container_Connection_For_Type    ${multiplied_type}    ${multiplicity}
    [Teardown]    NamedVms.Switch_To_Node_For_Index    1
