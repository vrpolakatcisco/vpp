*** Settings ***
Documentation     Suite to reset kueadm on hosts before running other suites.
Resource          ${CURDIR}/../libraries/setup-teardown.robot
Resource          ${CURDIR}/../libraries/KubernetesEnv.robot
Resource          ${CURDIR}/../variables/${VARIABLES}_variables.robot
Suite Setup       setup-teardown.Testsuite_Setup
Suite Teardown    setup-teardown.Testsuite_Teardown

*** Variables ***
${ENV}            common
${VARIABLES}      common

*** Test Cases ***
Reset
    [Documentation]    Execute "sudo kubeadm reset" on each host and reinit one node cluster.
    ...    The reinit is there because suite setup currently fails without it.
    : FOR    ${index}    IN RANGE    ${KUBE_CLUSTER_${CLUSTER_ID}_NODES}    0    -1
    \    SSHLibrary.Switch_Connection    ${VM_SSH_ALIAS_PREFIX}${index}
    \    SshCommons.Execute_Command_And_Log    sudo kubeadm reset
    # Connection to first node (master) is now active.
    BuiltIn.Comment    FIXME: This should not be needed, improve suite setup to tolerate:
    ...    'The connection to the server ... was refused'
    KubernetesEnv.Reinit_One_Node_Kube_Cluster
