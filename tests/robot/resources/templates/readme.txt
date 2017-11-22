Files here are text templates, containing fields Robot will replace with configurable values.
Fields:
$LOCATION    nodeSelector label, currently 2 values are supported: server_node (vm_2, slave) and client_node (vm_1, master).
$REPLICAS    how many pods of this type to deploy
$NAME        Common deployment name, service name, app label, container name, etc. Used as prefix in Robot.
             Robot should set different name if other field differ so that replica counting is reliable.
