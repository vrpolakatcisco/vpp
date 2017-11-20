*** Settings ***
Documentation     Suite to reset kubeadm on hosts before running other suites.
Resource          ${CURDIR}/../libraries/setup-teardown.robot
Resource          ${CURDIR}/../libraries/KubernetesEnv.robot
Suite Setup       setup-teardown.Testsuite_Setup
Suite Teardown    setup-teardown.Testsuite_Teardown

*** Test Cases ***
Reset
    [Documentation]    Execute "sudo kubeadm reset" on each host and reinit one node cluster.
    ...    The reinit is there because suite setup currently fails without it.
    : FOR    ${index}    IN RANGE    ${KUBE_CLUSTER_${CLUSTER_ID}_NODES}    0    -1
    \    SSHLibrary.Switch_Connection    ${VM_SSH_ALIAS_PREFIX}${index}
    \    SshCommons.Execute_Command_And_Log    sudo kubeadm reset
