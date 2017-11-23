*** Settings ***
Documentation     Suite to clean up docker on hosts after running other suites.
...               The idea is that there is still kubernetes running after the last suite,
...               so images used by that will not get deleted,
...               so the next run does not need to download them again.
Resource          ${CURDIR}/../libraries/all_libs.robot
Suite Setup       setup-teardown.Testsuite_Setup
Suite Teardown    setup-teardown.Testsuite_Teardown

*** Test Cases ***
Reset
    [Documentation]    Execute cleanup commands on each host.
    : FOR    ${index}    IN RANGE    ${KUBE_CLUSTER_${CLUSTER_ID}_NODES}    0    -1
    \    SSHLibrary.Switch_Connection    ${VM_SSH_ALIAS_PREFIX}${index}
    \    SshCommons.Execute_Command_And_Log    docker system prune -a -f
