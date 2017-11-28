*** Settings ***
Documentation     This is a library to handle actions related to kubernetes cluster as a whole.
...
...               If your action is specific to a node or a pod, look into other libraries.
...
...               This library assumes a SSH connection towards a relevant host machine is already active,
...               for most keywords it is the first (master) host.
Resource          ${CURDIR}/all_libs.robot

*** Variables ***
${COMMON_URL_BASE}    https://raw.githubusercontent.com/contiv/vpp/master/k8s
${CRI_INSTALL_SCRIPT_ULR}    ${COMMON_URL_BASE}/cri-install.sh
${KUBE_PROXY_SCRIPT_URL}    ${COMMON_URL_BASE}/proxy-install.sh
${NV_PLUGIN_URL}    ${COMMON_URL_BASE}/contiv-vpp.yaml
${VPP_IMAGES_SCRIPT_URL}    ${COMMON_URL_BASE}/pull-images.sh

*** Keywords ***
Unsafe_On_Master_Host_Connection
    [Arguments]    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Switch to first host SSH connection, execute keyword, return the results. Note connection remains switched.
    BuiltIn.Log_Many    ${keyword}    ${args}    ${kwargs}
    NamedVms.Switch_To_Node_For_Index    1
    Builtin.Run_Keyword_And_Return    ${keyword}    @{args}    &{kwargs}

On_Master_Host_Connection
    [Arguments]    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Switch to first host SSH connection, execute keyword, switch back, return the results.
    ...    This is typically used for kubectl commands, as they do not usually work on slave hosts.
    BuiltIn.Log_Many    ${keyword}    ${args}    ${kwargs}
    BuiltIn.Run_Keyword_And_Return    SshCommons.Run_Keyword_Preserve_Connection    Unsafe_On_Master_Host_Connection    ${keyword}    @{args}    &{kwargs}

Apply_F
    [Arguments]    ${file_path}
    [Documentation]    Execute "kubectl apply -f" with given local file.
    BuiltIn.Log_Many    ${file_path}
    SshCommons.Execute_Command_With_Copied_File    kubectl apply -f    ${file_path}

Apply_F_Url
    [Arguments]    ${url}
    [Documentation]    Execute "kubectl apply -f" with given \${url}.
    BuiltIn.Log_Many    ${url}
    SshCommons.Execute_Command_And_Log    kubectl apply -f ${url}

Delete_F
    [Arguments]    ${file_path}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Execute "kubectl delete -f" with given local file.
    BuiltIn.Log_Many    ${file_path}    ${expected_rc}    ${ignore_stderr}
    SshCommons.Execute_Command_With_Copied_File    kubectl delete -f    ${file_path}    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Delete_F_Url
    [Arguments]    ${url}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Execute "kubectl delete -f" with given \${url}.
    BuiltIn.Log_Many    ${url}    ${expected_rc}    ${ignore_stderr}
    SshCommons.Execute_Command_And_Log    kubectl delete -f ${url}    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Check_K8s_Node_Settings
    [Arguments]    ${index}
    [Documentation]    For node given by index, fail if it is non-master first node, or non-slave other node.
    BuiltIn.Log_Many    ${index}
    ${role} =    NamedVms.Get_Host_Role_For_Index    ${index}
    BuiltIn.Run_Keyword_If    """${index}""" == "1" and """${role}""" != "master"   BuiltIn.Fail    Node ${index} should be kubernetes master.
    BuiltIn.Run_Keyword_If    """${index}""" != "1" and """${role}""" != "slave"   BuiltIn.Fail    Node ${index} should be kubernetes slave.

Uninstall_Cri_Shim
    [Documentation]    Execute bash applying script from ${CRI_INSTALL_SCRIPT_ULR} with -u argument and ignoring errors.
    SshCommons.Execute_Command_And_Log    curl -s ${CRI_INSTALL_SCRIPT_ULR} | sudo bash /dev/stdin -u    ignore_stderr=${True}    ignore_rc=${True}

Docker_Pull_Contiv_Vpp
    [Documentation]    Execute bash applying script from ${VPP_IMAGES_SCRIPT_URL}
    SshCommons.Execute_Command_And_Log    bash <(curl -s ${VPP_IMAGES_SCRIPT_URL})

Docker_Pull_Custom_Kube_Proxy
    [Documentation]    Execute bash applying script from ${KUBE_PROXY_SCRIPT_URL}
    SshCommons.Execute_Command_And_Log    bash <(curl -s ${KUBE_PROXY_SCRIPT_URL})

Install_Cri_Shim
    [Documentation]    Execute bash applying script from ${CRI_INSTALL_SCRIPT_ULR}.
    SshCommons.Execute_Command_And_Log    curl -s ${CRI_INSTALL_SCRIPT_ULR} | sudo bash /dev/stdin

Reset_Cluster_Node
    [Documentation]    Remove .kube/, kubeadm reset, pull vpp images, install cri shim.
    SshCommons.Execute_Command_And_Log    sudo rm -rf $HOME/.kube
    NodeManagement.KubeAdm_Reset
    Uninstall_Cri_Shim
    NodeManagement.KubeAdm_Reset
    Docker_Pull_Contiv_Vpp
    Docker_Pull_Custom_Kube_Proxy
    Install_Cri_Shim

Apply_Contiv_Vpp_Plugin
    [Documentation]    Apply from URL ${NV_PLUGIN_URL}
    Apply_F_Url    ${NV_PLUGIN_URL}

Init_Master_Node
    [Documentation]   Execute commands specific for master initialization, return stdout from init command.
    ...    TODO: Improve this Documentation?
    ${init_stdout} =    NodeManagement.KubeAdm_Init
    BuiltIn.Should_Contain    ${init_stdout}    Your Kubernetes master has initialized successfully
    SshCommons.Execute_Command_And_Log    mkdir -p $HOME/.kube
    SshCommons.Execute_Command_And_Log    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    SshCommons.Execute_Command_And_Log    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    NodeManagement.Taint_Active_Node    nodes --all node-role.kubernetes.io/master-
    Apply_Contiv_Vpp_Plugin
    [Return]    ${init_stdout}

Check_All_Pods_Running
    [Arguments]    ${excluded_pod_prefix}=invalid-pod-prefix-
    [Documentation]     Iterate over all pods of all namespaces (skipping \${excluded_pod_prefix} matches), check running state.
    BuiltIn.Log_Many    ${excluded_pod_prefix}
    &{pods} =    PodManagement.Get_Pods_Full    options=--all-namespaces
    @{pod_names} =    Collections.Get_Dictionary_Keys    &{pods}
    : FOR    ${name}   IN    @{pod_names}
    \     BuiltIn.Continue_For_Loop_If    """${pod_name}""".startswith("""${excluded_pod_prefix}""")
    \     ${namespace} =    BuiltIn.Evaluate    &{pods}[${pod_name}]['NAMESPACE']
    \     PodManagement.Check_Pod_Running_Containers_Ready    ${pod_name}    namespace=${namespace}

Check_K8s_With_Plugin_Running
    [Arguments]    ${exp_nr_pods}=9    ${excluded_pod_prefix}=invalid-pod-prefix-
    [Documentation]     Check \${exp_nr_pods} (of not ignored) pods are visible and running after init.
    BuiltIn.Log_Many    ${exp_nr_pods}    ${excluded_pod_prefix}
    PodManagement.Check_For_Multiplicity    prefix=${EMPTY}    multiplicity=${exp_nr_pods}    namespace=${EMPTY}    options=--all-namespaces
    Check_All_Pods_Running

Join_Other_Node
    [Arguments]    ${index}    ${join_cmd}
    [Documentation]    If \${index} is more than 1, execute \${join_cmd} ignoring stderr.
    BuiltIn.Log_Many    ${index}    ${join_cmd}
    BuiltIn.Return_From_Keyword_If    ${index} <= 1
    SshCommons.Execute_Command_And_Log    sudo ${join_cmd}    ignore_stderr=${True}

Get_Nodes
    [Documentation]    Execute "kubectl get nodes" on active connection, parse, log and return the parsed outpt.
    ${stdout} =    SshCommons.Execute_Command_And_Log    kubectl get nodes
    ${output} =    kube_parser.parse_kubectl_get_nodes    ${stdout}
    BuiltIn.Log    ${output}
    [Return]    ${output}

Check_Cluster_Ready
    [Arguments]     ${nr_nodes}
    [Documentation]    Get nodes, check there are \${nr_nodes}, for each node Verify_Cluster_Node_Ready.
    BuiltIn.Log_Many     ${nr_nodes}
    &{nodes} =    Get_Nodes
    BuiltIn.Length_Should_Be    ${nodes}    ${nr_nodes}
    ${names} =     Collections.Get_Dictionary_Keys     &{nodes}
    : FOR    ${name}    IN    @{names}
    \    ${status} =    BuiltIn.Evaluate    &{nodes}[${name}]['STATUS']
    \    BuiltIn.Should_Be_Equal    ${status}    Ready

Wait_Until_Cluster_Ready
    [Arguments]    ${nr_nodes}    ${timeout}=180s    ${check_period}=5s
    [Documentation]    WUKS around Check_Cluster_Ready.
    BuiltIn.Log_Many    ${nr_nodes}    ${timeout}    ${check_period}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${check_period}    Check_Cluster_Ready    ${nr_nodes}

Reinit_Kube_Cluster
    [Arguments]    ${nr_nodes}
    [Documentation]    Assuming SSH connections with known aliases are created, check roles,
    ...    reset nodes, init master, wait to see it running, join other nodes, wait until cluster is ready.
    ...    The argument is there override the number of nodes, so 1-node suites work on 2-node deployments well.
    Builtin.Log_Many    ${nr_nodes}
    NamedVms.For_Each_Machine_Call_With_Index_Without_Switch    ${nr_nodes}    Check_K8s_Node_Settings
    # Node reset is the only action which applies to 2nd node in 1node suite.
    ${max_size} =    NamedVms.Get_Cluster_Max_Size
    NamedVms.For_Each_Machine_Switch_And_Call    ${max_size}    Reset_Cluster_Node
    # Master node SSH connection is active.
    ${init_stdout} =    Init_Master_Node
    BuiltIn.Wait_Until_Keyword_Succeeds    240s    10s    Check_K8s_With_Plugin_Running
    ${join_cmd} =    kube_parser.get_join_from_kubeadm_init    ${init_stdout}
    NamedVms.For_Each_Machine_Switch_And_Call_With_Index    ${nr_nodes}    Join_Other_Node
    # Master node SSH connection is active.
    Wait_Until_Cluster_Ready    ${nr_nodes}
    NamedVms.For_Each_Machine_Call_With_Index_Without_Switch    ${nr_nodes}    Label_Node_For_Index
