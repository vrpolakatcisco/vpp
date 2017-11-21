*** Settings ***
Documentation     This is a library to handle actions related to pods from host point of view,
...
...               Do not add keywords which access data from cluster point of view.
...               Do not add keywords which access processes inside pods (except getting logs created by them).
...               Also do not add keywords which merely download images, apply plugins,
...               or do other things not related to state of pods.
...
...               Keywords here are for creating and deleting pods, querying,
...               waiting and other pod actions executed on host.
...
...               This library does not manage any suite variables,
...               everything is passed via arguments and return values.
...
...               Each keyword assumes SSH connection towards the required node is active.
Library           String
Library           Collections
Library           ${CURDIR}/kube_parser.robot
Resource          ${CURDIR}/KubeCtl.robot

*** Keywords ***
Get_Logs
    [Arguments]    ${pod_name}    ${container}=${EMPTY}    ${namespace}=${EMPTY}
    [Documentation]    Execute "kubectl logs" with given parameters and return the result.
    BuiltIn.Log_Many    ${pod_name}    ${container}    ${namespace}
    ${nsparam} =     BuiltIn.Set_Variable_If    """${namespace}"""    ${SPACE}--namespace ${namespace}    ${EMPTY}
    ${cntparam} =    BuiltIn.Set_Variable_If    """${container}"""    ${SPACE}${container}    ${EMPTY}
    BuiltIn.Run_Keyword_And_Return    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl logs${nsparam} ${pod_name}${cntparam}

Describe_Pod
    [Arguments]    ${pod_name}
    [Documentation]    Execute "kubectl describe pod" with given \${pod_name}, parse, log and return the parsed details.
    BuiltIn.Log_Many    ${pod_name}
    ${output} =    SshCommons.Execute_Command_And_Log    kubectl describe pod ${pod_name}
    ${details} =   kube_parser.parse_kubectl_describe_pod    ${output}
    BuiltIn.Log    ${details}
    [Return]    ${details}

Get_Host_Ip_For_Pod_Name
    [Arguments]    ${name}
    [Documentation]    Call Describe_Pod, parse IP address, log and return it.
    ...    This is useful for determining --no-proxy target.
    BuiltIn.Log_Many    ${name}
    ${details} =    Describe_Pod    ${name}
    ${ip} =    BuiltIn.Evaluate    &{details}[${name}]["IP"]
    BuiltIn.Log    ${ip}
    [Return]    ${ip}

Get_Pods_Full
    [Arguments]    ${namespace}=${EMPTY}    ${options}=${EMPTY}
    [Documentation]    Execute "kubectl get pods" with optional arguments for given \${namespace} and \${options},
    ...    tolerating zero resources, parse, log and return the parsed output.
    BuiltIn.Log_Many    ${namespace}    ${options}
    ${spaced_namespace} =    BuiltIn.Set_Variable_If    """${namespace}"""    ${SPACE}-n ${namespace}    ${EMPTY}
    ${spaced_options} =    BuiltIn.Set_Variable_If    """${options}"""    ${SPACE}${options}    ${EMPTY}
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    SshCommons.Execute_Command_And_Log    kubectl get pods${spaced_namespace}${spaced_options}
    BuiltIn.Run_Keyword_If    """${status}""" == """FAIL""" and """No resources found""" not in """${message}"""    BuiltIn.Fail    msg=${message}
    ${output} =    kube_parser.parse_kubectl_get_pods    ${message}
    BuiltIn.Log    ${output}
    [Return]    ${output}

Get_Pod_Names
    [Arguments]    ${prefix}=${EMPTY}    ${namespace}=${EMPTY}    ${options}=${EMPTY}
    [Documentation]    Get parsed outpt for pods of given \${namespace},
    ...    return list of pod names starting with \${prefix}.
    BuiltIn.Log_Many    ${prefix}    ${namespace}    ${options}
    &{pods} =    Get_Pods    namespace=${namespace}    options=${options}
    @{pod_names} =    Collection.Get_Dictionary_Keys    &{pods}
    @{matched_names} =    BuiltIn.Create_List
    : FOR    ${name}    IN    @{pod_names}
    \    BuiltIn.Run_Keyword_If    """${name}""".startswith("""${prefix}""")    Collections.Append_To_List    ${matched_names}    ${name}
    BuiltIn.Log    ${matched_names}
    [Return]    ${matched_names}

Check_Pod_Multiplicity
    [Arguments]    ${prefix}    ${multiplicity}=1    ${namespace}=default    ${options}=${EMPTY}
    [Documentation]    Call Get_Pod_Names, check name list length matches multiplicity, return name list.
    BuiltIn.Log_Many    ${prefix}    ${multiplicity}    ${namespace}    ${options}
    ${pod_names} =    Get_Pod_Names    ${prefix}    ${namespace}    ${options}
    BuiltIn.Length_Should_Be    ${pod_names}    ${multiplicity}
    [Return]    ${pod_names}

Get_Single_Pod_Name
    [Arguments]    ${prefix}    ${namespace}=default    ${options}=${EMPTY}
    [Documentation]    Check the multiplicity for \${prefix} is 1, log and return the pod name.
    BuiltIn.Log_Many    ${prefix}    ${namespace}    ${options}
    ${pod_names} =    Check_Pod_Multiplicity    ${prefix}    1    ${namespace}    ${options}
    ${name} =    Collections.Get_From_List    ${pod_names}    0
    BuiltIn.Log    ${name}
    [Return]    ${name}

Wait_For_Pod_Multiplicity
    [Arguments]    ${prefix}    ${multiplicity}=1    ${namespace}=default    ${options}=${EMPTY}    ${timeout}=10s    ${check_period}=2s
    [Documentation]    WUKS around Check_Pod_Multiplicity.
    BuiltIn.Log_Many    ${prefix}    ${multiplicity}    ${namespace}    ${options}    ${timeout}    ${check_period}
    Builtin.Comment    TODO: Is it better to inline this and save 1 call depth at cost of prolonging the caller line?
    Builtin.Run_Keyword_And_Return    Builtin.Wait_Until_Keyword_Succeeds    ${timeout}    ${check_period}    Check_Pod_Multiplicity    ${prefix}    ${multiplicity}    ${namespace}    ${options}

Check_Pod_Running_Containers_Ready
    [Arguments]    ${pod_name}    ${namespace}=default    ${options}=${EMPTY}
    [Documentation]    Get pods of \${namespace}, parse status of \${pod_name}, check it is Running,
    ...    parse for ready containes of \${pod_name}, check it is all of them.
    BuiltIn.Log_Many    ${pod_name}    ${namespace}    ${options}
    &{pods} =     Get_Pods_Full    namespace=${namespace}    options=${options}
    ${status} =    BuiltIn.Evaluate    &{pods}[${pod_name}]['STATUS']
    BuiltIn.Should_Be_Equal_As_Strings    ${status}    Running
    ${ready} =    BuiltIn.Evaluate    &{pods}[${pod_name}]['READY']
    ${ready_containers}    ${out_of_containers} =    String.Split_String    ${ready}    separator=${/}    max_split=1
    BuiltIn.Should_Be_Equal_As_Strings    ${ready_containers}    ${out_of_containers}

Check_Pods_Running
    [Arguments]    ${pod_names}    ${namespace}=default    ${options}=${EMPTY}
    [Documentation]    Call Check_Pod_Running_Containers_Ready for each name in \${pod_names}.
    ...    This is a separate keyword so that it can be called from WUKS while extracting the for cycle.
    ...    And alternative of having WUKS inside FOR could take too long to finish in case of big failure.
    BuiltIn.Log_Many    ${pod_names}    ${namespace}    ${options}
    : FOR    ${name}    IN    ${pod_names}
    \    Check_Pod_Running_Containers_Ready    ${name}    ${namespace}

Wait_For_Pods_Running
    [Arguments]    ${pod_names}    ${namespace}=default    ${options}=${EMPTY}    ${timeout}=30s    ${check_period}=5s
    [Documentation]    WUKS around Check_Pod_Running_Containers_Ready.
    BuiltIn.Log_Many    ${pod_names}    ${namespace}    ${options}    ${timeout}    ${check_period}
    Builtin.Comment    TODO: Is it better to inline this and save 1 call depth at cost of prolonging the caller line?
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${check_period}    Check_Pods_Running    ${pod_names}    namespace=${namespace}    options=${options}

Deploy_Pods_And_Verify_Running
    [Arguments]    ${pod_file}    ${pod_prefix}    ${multiplicity}=1    ${namespace}=defaut    ${options}=${EMPTY}    ${timeout}=30s    ${check_period}=5s
    [Documentation]    Deploy pods defined by \${pod_file}, wait until pods matching \${pod_prefix} reach ${multiplicity},
    ...    wait until pods are running with ready containers, log and return the list of pod names.
    Builtin.Log_Many    ${pod_file}    ${pod_prefix}    ${multiplicity}    ${namespace}    ${options}    ${timeout}    ${check_period}
    KubeCtl.Apply_F    ${pod_file}
    ${pod_names} =    Wait_For_Pod_Multiplicity    ${pod_prefix}    ${multiplicity}    ${namespace}    ${timeout}    ${options}    ${check_period}
    Wait_Until_Pods_Running    ${pod_names}    namespace=${namespace}    ${options}
    [Return]    ${pod_names}

Remove_Pods_And_Verify_Removed
    [Arguments]    ${pod_file}    ${pod_prefix}    ${namespace}=default    ${options}=${EMPTY}    ${expected_rc}=0    ${ignore_stderr}=${False}    ${timeout}=30s    ${check_period}=5s
    [Documentation]    Remove pod defined by \${pod_file}, wait for \${pod_prefix} multiplicity reach zero.
    BuiltIn.Log_Many    ${pod_file}    ${pod_prefix}    ${namespace}    ${options}    ${expected_rc}    ${ignore_stderr}    ${timeout}    ${check_period}
    KubeCtl.Delete_F    ${pod_file}    ${expected_rc}    ${ignore_stderr}
    Wait_For_Pod_Multiplicity    ${pod_prefix}    0    ${namespace}    ${options}    ${timeout}    ${check_period}
