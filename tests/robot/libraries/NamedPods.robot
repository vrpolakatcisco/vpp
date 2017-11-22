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
Resource          ${CURDIR}/all_libs.robot

*** Variables ***
${CLIENT_ISTIO_FILE}    ${CURDIR}/../resources/one-ubuntu-istio.yaml
${CLIENT_FILE}    ${CURDIR}/../resources/ubuntu-client.yaml
${CLIENT_FILE_NODE1}    ${CURDIR}/../resources/ubuntu-client-node1.yaml
${CLIENT_PREFIX}    ubuntu-client
${ISTIO_FILE}    ${CURDIR}/../resources/istio029.yaml
${ISTIO_PREFIX}    istio-system
${NGINX_10_FILE}    ${CURDIR}/../resources/nginx10.yaml
${NGINX_10_PREFIX}    nginx
${NGINX_ISTIO_FILE}    ${CURDIR}/../resources/nginx-istio.yaml
${NGINX_FILE}    ${CURDIR}/../resources/nginx.yaml
${NGINX_FILE_NODE2}    ${CURDIR}/../resources/nginx-node2.yaml
${NGINX_PREFIX}    nginx
${PRELOAD_CLIENT_FILE}   ${CURDIR}/../resources/one-ldpreload-client-iperf.yaml
${PRELOAD_CLIENT_POD_PREFIX}    test-client
${PRELOAD_SERVER_FILE}   ${CURDIR}/../resources/one-ldpreload-server-iperf.yaml
${PRELOAD_SERVER_PREFIX}    test-server-iperf
${SERVER_FILE_NODE2}    ${CURDIR}/../resources/ubuntu-server-node2.yaml
${SERVER_FILE}    ${CURDIR}/../resources/ubuntu-server.yaml
${SERVER_PREFIX}    ubuntu-server

*** Keywords ***
Deploy_Single_Client_And_Verify_Running
    [Arguments]    ${file}=${CLIENT_FILE}
    [Documentation]     Deploy client ubuntu pod, return its name. Pod name in the yaml file is expected to be ${CLIENT_PREFIX}.
    Builtin.Log_Many    ${file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${file}    ${CLIENT_PREFIX}-
    [Return]    @{names}[0]

Deploy_Single_Preload_Client_And_Verify_Running
    [Arguments]    ${file}=${PRELOAD_CLIENT_FILE}
    [Documentation]     Deploy client ubuntu pod, return its name. Pod name in the yaml file is expected to be ${PRELOAD_CLIENT_PREFIX}.
    Builtin.Log_Many    ${file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${file}    ${PRELOAD_CLIENT_PREFIX}-
    [Return]    @{names}[0]

Deploy_Single_Server_And_Verify_Running
    [Arguments]    ${file}=${SERVER_FILE}
    [Documentation]     Deploy server ubuntu pod. Pod name in the yaml file is expected to be ${SERVER_PREFIX}.
    BuiltIn.Log_Many    ${file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${file}    ${SERVER_PREFIX}-
    [Return    @{names}[0]

Deploy_Single_Preload_Server_And_Verify_Running
    [Arguments]    ${file}=${PRELOAD_SERVER_FILE}
    [Documentation]     Deploy server ubuntu pod. Pod name in the yaml file is expected to be ${PRELOAD_SERVER_PREFIX}.
    BuiltIn.Log_Many    ${file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${file}    ${PRELOAD_SERVER_PREFIX}-
    [Return    @{names}[0]

Deploy_Single_Nginx_And_Verify_Running
    [Arguments]    ${file}=${NGINX_FILE}
    [Documentation]     Deploy one nginx pod and. Pod name in the yaml file is expected to be ${NGINX_PREFIX}.
    BuiltIn.Log_Many    ${file}
    ${names} =    PodManagement.Deploy_Pods_And_Verify_Running    ${file}    ${NGINX_PREFIX}-
    [Return]    @{names}[0]

Deploy_Multiple_Nginx_10_And_Verify_Running
    [Arguments]    ${file}=${NGINX_10_FILE}    ${multiplicity}=10
    [Documentation]     Deploy 10 nginx pods, wait to see them running, return their names.
    BuiltIn.Log_Many    ${file}    ${multiplicity}
    BuiltIn.Run_Keyword_And_Return    PodManagement.Deploy_Pods_And_Verify_Running    ${file}    ${NGINX_10_PREFIX}    ${multiplicity}

Deploy_Multiple_Istio_And_Verify_Running
    [Arguments]    ${file}=${ISTIO_FILE}    ${multiplicity}=5
    [Documentation]     Deploy istio pods, wait to see them running, return their names.
    BuiltIn.Log_Many    ${file}    ${multiplicity}
    BuiltIn.Run_Keyword_And_Return    PodManagement.Deploy_Pods_And_Verify_Running    ${file}    ${ISTIO_PREFIX}    ${multiplicity}

Remove_Client_And_Verify_Removed
    [Arguments]    ${file}=${CLIENT_FILE}
    [Documentation]    Execute delete command for client pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${file}
    PodManagement.Remove_Pods_And_Verify_Removed    ${file}    ${CLIENT_PREFIX}-

Remove_Preload_Client_And_Verify_Removed
    [Arguments]    ${file}=${PRELOAD_CLIENT_FILE}
    [Documentation]    Execute delete command for client pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${file}
    PodManagement.Remove_Pods_And_Verify_Removed    ${file}    ${PRELOAD_CLIENT_PREFIX}-

Remove_Server_And_Verify_Removed
    [Arguments]    ${file}=${SERVER_FILE}
    [Documentation]    Execute delete command for server pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${file}    ${SERVER_PREFIX}-

Remove_Preload_Server_And_Verify_Removed
    [Arguments]    ${file}=${PRELOAD_SERVER_FILE}
    [Documentation]    Execute delete command for server pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${file}    ${PRELOAD_SERVER_PREFIX}-

Remove_Nginx_And_Verify_Removed
    [Arguments]    ${file}=${NGINX_FILE}
    [Documentation]    Execute delete command for nginx pod, wait until the pod is removed.
    BuiltIn.Log_Many    ${file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${file}    ${NGINX_PREFIX}-

Remove_Nginx_10_And_Verify_Removed
    [Arguments]    ${file}=${NGINX_10_FILE}
    [Documentation]    Execute delete command for 10 nginx pods, wait until the pods are removed.
    BuiltIn.Log_Many    ${file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${file}    ${NGINX_10_PREFIX}-

Remove_Istio_And_Verify_Removed
    [Arguments]    ${file}=${ISTIO_FILE}
    [Documentation]     Remove istio pods expecting rc=1 and ignoring stderr, verify no istio pod remains.
    BuiltIn.Log_Many    ${file}
    PodManagement.Remove_Pod_And_Verify_Removed    ${file}    ${ISTIO_PREFIX}    expected_rc=1    ignore_stderr=${True}

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
