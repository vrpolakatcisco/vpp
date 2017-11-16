*** Settings ***
Documentation     Suite to clean up hosts before running other suites.
Resource          ${CURDIR}/../libraries/setup-teardown.robot
Suite Setup       setup-teardown.Testsuite_Setup
Suite Teardown    setup-teardown.Testsuite_Teardown

*** Variables ***
${ENV}            common
${VARIABLES}      common

*** Test Cases ***
Reset
    [Documentation]    Execute cleanup commands on each host.
    : FOR    ${index}    IN RANGE    ${KUBE_CLUSTER_${CLUSTER_ID}_NODES}    0    -1
    \    SSHLibrary.Switch_Connection    ${VM_SSH_ALIAS_PREFIX}${index}
    \    SshCommons.Execute_Command_And_Log    kubeadm reset
    \    SshCommons.Execute_Command_And_Log    docker system prune -a -f
