*** Settings ***
Documentation     This is a library to handle kubectl commands on the remote machine, towards which
...    ssh connection is opened.
Library           Collections
Library           SSHLibrary
Library           String
Library           ${CURDIR}/kube_parser.py
Resource          ${CURDIR}/SshCommons.robot

*** Keywords ***
Apply_F
    [Arguments]    ${ssh_session}    ${file_path}
    [Documentation]    Execute "kubectl apply -f" with given local file.
    SshCommons.Switch_And_Execute_With_Copied_File    ${ssh_session}    ${file_path}    kubectl apply -f

Apply_F_Url
    [Arguments]    ${ssh_session}    ${url}
    [Documentation]    Execute "kubectl apply -f" with given \${url}.
    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl apply -f ${url}

Delete_F
    [Arguments]    ${ssh_session}    ${file_path}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Execute "kubectl delete -f" with given local file.
    SshCommons.Switch_And_Execute_With_Copied_File    ${ssh_session}    ${file_path}    kubectl delete -f    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Delete_F_Url
    [Arguments]    ${ssh_session}    ${url}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Execute "kubectl delete -f" with given \${url}.
    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl delete -f ${url}    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Get_Pod
    [Arguments]    ${ssh_session}    ${pod_name}    ${namespace}=default
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl get pod -n ${namespace} ${pod_name}
    ${output} =    kube_parser.parse_kubectl_get_pods    ${stdout}
    BuiltIn.Return_From_Keyword    ${output}

Get_Pods
    [Arguments]    ${ssh_session}    ${namespace}=default 
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl get pods -n ${namespace}
    BuiltIn.Run_Keyword_If    """${status}""" == """FAIL""" and """No resources found""" not in """${message}"""    FAIL    msg=${message}
    ${output} =    kube_parser.parse_kubectl_get_pods    ${message}
    BuiltIn.Return_From_Keyword    ${output}

Get_Pods_Wide
    [Arguments]    ${ssh_session}
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl get pods -o wide
    ${output} =    kube_parser.parse_kubectl_get_pods    ${stdout}
    BuiltIn.Return_From_Keyword    ${output}

Get_Pods_All_Namespaces
    [Arguments]    ${ssh_session}
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl get pods --all-namespaces
    ${output} =    kube_parser.parse_kubectl_get_pods    ${stdout}
    BuiltIn.Return_From_Keyword    ${output}

Get_Nodes
    [Arguments]    ${ssh_session}
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl get nodes
    ${output} =    kube_parser.parse_kubectl_get_nodes    ${stdout}
    BuiltIn.Return_From_Keyword    ${output}

Logs
    [Arguments]    ${ssh_session}    ${cmd_param}
    BuiltIn.Run_Keyword_And_Return    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl logs ${cmd_param}

Describe_Pod
    [Arguments]    ${ssh_session}    ${pod_name}
    ${output} =    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl describe pod ${pod_name}
    ${details} =   kube_parser.parse_kubectl_describe_pod    ${output}
    BuiltIn.Return_From_Keyword    ${details}

Taint
    [Arguments]    ${ssh_session}    ${cmd_parameters}
    ${stdout} =    SshCommons.Switch_And_Execute_Command    ${ssh_session}    kubectl taint ${cmd_parameters}
    BuiltIn.Return_From_Keyword    ${stdout}
