*** Settings ***
Documentation     This is an extension to PodManagement with keywords named for specific yaml files.
...
...               All keywords assume active SSH connection points to the desired host.
...
...               The code is aimed at few selected deployments:
...               A: 1-node 2-pod, client and server pods: no specific applications, test use pind and nc to check connectivity.
...               B: 1-node 2-pod, client and nginx pods: nginx runs a web server, client uses curl to check, otherwise as B.
...               C: 1-node 2-pod, client and server istio pods: As A but both pods contain istio proxy.
...               D: 1-node 2-pod, client and nginx istio pods: As B but both pods contain istio proxy.
...               TODO: Describe 10-pod deployment.
...
...               This Resource manages the following suite variables:
...               ${testbed_connection} SSH connection index towards host in 1-node k8s cluster.
...               ${istio_pods} list of pods matching istio prefix last seen running.
...               FIXME: The pod names should be known, hardcode them as prefixes.
Resource          ${CURDIR}/PodManagement.robot

*** Variables ***
${CLIENT_ISTIO_POD_FILE}    ${CURDIR}/../resources/one-ubuntu-istio.yaml
${CLIENT_POD_FILE}    ${CURDIR}/../resources/ubuntu-client.yaml
${CLIENT_POD_FILE_NODE1}    ${CURDIR}/../resources/ubuntu-client-node1.yaml
${CLIENT_PREFIX}    ubuntu-client
${ISTIO_FILE}    ${CURDIR}/../resources/istio029.yaml
${ISTIO_PREFIX}    istio-system
${NGINX_10_POD_FILE}    ${CURDIR}/../resources/nginx10.yaml
${NGINX_ISTIO_POD_FILE}    ${CURDIR}/../resources/nginx-istio.yaml
${NGINX_POD_FILE}    ${CURDIR}/../resources/nginx.yaml
${NGINX_POD_FILE_NODE2}    ${CURDIR}/../resources/nginx-node2.yaml
${NGINX_PREFIX}    nginx
${SERVER_POD_FILE_NODE2}    ${CURDIR}/../resources/ubuntu-server-node2.yaml
${SERVER_POD_FILE}    ${CURDIR}/../resources/ubuntu-server.yaml
${SERVER_PREFIX}    ubuntu-server

*** Keywords ***
Deploy_Single_Client_Pod_And_Verify_Running
    [Arguments]    ${client_file}=${CLIENT_POD_FILE}
    [Documentation]     Deploy client ubuntu pod, return its name. Pod name in the yaml file is expected to be ${CLIENT_PREFIX}.
    Builtin.Log_Many    ${client_file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${client_file}    ${CLIENT_PREFIX}-
    [Return]    @{names}[0]

Deploy_Single_Server_Pod_And_Verify_Running
    [Arguments]    ${server_file}=${SERVER_POD_FILE}
    [Documentation]     Deploy server ubuntu pod. Pod name in the yaml file is expected to be ${SERVER_PREFIX}.
    BuiltIn.Log_Many    ${server_file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${server_file}    ${SERVER_PREFIX}-
    [Return    @{names}[0]

Deploy_Single_Nginx_Pod_And_Verify_Running
    [Arguments]    ${nginx_file}=${NGINX_POD_FILE}
    [Documentation]     Deploy one nginx pod and. Pod name in the yaml file is expected to be ${NGINX_PREFIX}.
    BuiltIn.Log_Many    ${nginx_file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${nginx_file}    ${NGINX_PREFIX}-
    [Return]    @{names}[0]

Remove_Client_Pods_And_Verify_Removed
    [Arguments]    ${client_file}=${CLIENT_POD_FILE}
    [Documentation]    Execute delete command for client pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${client_file}
    PodManagement.Remove_Pods_And_Verify_Removed    ${client_file}    ${CLIENT_PREFIX}-

Remove_Server_Pods_And_Verify_Removed
    [Arguments]    ${server_file}=${SERVER_POD_FILE}
    [Documentation]    Execute delete command for server pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${server_file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${server_file}    ${SERVER_PREFIX}-

Remove_Nginx_Pods_And_Verify_Removed
    [Arguments]    ${nginx_file}=${NGINX_POD_FILE}
    [Documentation]    Execute delete command for nginx pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${nginx_file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${nginx_file}    ${NGINX_PREFIX}-

Deploy_Istio_And_Verify_Running
    [Arguments]    ${istio_file}=${ISTIO_FILE}    ${multiplicity}=5
    [Documentation]     Deploy istio pods, wait to see them running, return their names.
    BuiltIn.Log_Many    ${istio_file}    ${multiplicity}
    BuiltIn.Run_Keyword_And_Return    PodManagement.Deploy_Pods_And_Verify_Running    ${istio_file}    ${ISTIO_PREFIX}    ${multiplicity}

Remove_Istio_And_Verify_Removed
    [Arguments]    ${istio_file}=${ISTIO_FILE}
    [Documentation]     Remove istio pods expecting rc=1 and ignoring stderr, verify no istio pod remains.
    BuiltIn.Log_Many    ${istio_file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${istio_file}    ${ISTIO_PREFIX}    expected_rc=1    ignore_stderr=${True}

Log_Contiv_Etcd
    [Documentation]    Check there is exactly one etcd pod, get its logs
    ...    (and do nothing with them, except the implicit Log).
    ${pod_name} =    PodManagement.Get_Single_Pod_Name    contiv-etcd-
    KubeCtl.Logs    ${pod_name}    namespace=kube-system

Log_Contiv_Ksr
    [Documentation]    Check there is exactly one ksr pod, get its logs
    ...    (and do nothing with them, except the implicit Log).
    ${pod_name} =    Get_Single_Pod_Name    contiv-ksr-
    KubeCtl.Logs    ${pod_name}    namespace=kube-system

Log_Contiv_Vswitch
    [Arguments]    ${multiplicity}=${KUBE_CLUSTER_${CLUSTER_ID}_NODES}
    [Documentation]    Check there is expected number of vswitch pods, get logs from them and cni containers
    ...    (and do nothing except the implicit Log).
    Builtin.Log_Many    ${multiplicity}
    ${pod_list} =    Check_Pod_Multiplicity    contiv-vswitch-    ${multiplicity}
    : FOR    ${name}    IN    @{pod_list}
    \    KubeCtl.Logs    ${name}    namespace=kube-system    container=contiv-cni
    \    KubeCtl.Logs    ${name}    namespace=kube-system    container=contiv-vswitch

Log_Kube_Dns
    [Documentation]    Check there is exactly one dns pod, get logs from kubedns, dnsmasq and sidecar containers
    ...    (and do nothing with them, except the implicit Log).
    ${pod_name} =    Get_Single_Pod_Name    kube-dns-
    KubeCtl.Logs    ${pod_name}    namespace=kube-system    container=kubedns
    KubeCtl.Logs    ${pod_name}    namespace=kube-system    container=dnsmasq
    KubeCtl.Logs    ${pod_name}    namespace=kube-system    container=sidecar

Log_Pods_For_Debug
    [Arguments]    ${nr_vswitch}=${KUBE_CLUSTER_${CLUSTER_ID}_NODES}
    [Documentation]    Call multiple keywords to get various logs
    ...    (and do nothing with them, except the implicit Log).
    Builtin.Log_Many    ${nr_vswitch}
    Log_Contiv_Etcd
    Log_Contiv_Ksr
    Log_Contiv_Vswitch    ${nr_vswitch}
    Log_Kube_Dns
