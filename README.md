ISCSI target pod for OpenShift testings.

# Target Setup
ISCSI target setup needs to run a privileged container with `SYS_MODULE` capability and `/lib/modules` mount directory, you can do this with:

```
oc create -f scc.yml
oc create -f iscsi-target.yml
```

After your pod is created, run `oc get pod iscsi-target -o yaml | grep podIP`, the IP address will be used later for your initiator setup.

# Initiator Setup
Initiator must be setup properly on every node of your cluster, run the following commands on your nodes:

```
yum -y install iscsi-initiator-utils
echo 'InitiatorName=iqn.2016-04.test.com:test.img' > /etc/iscsi/initiatorname.iscsi

cat >> /etc/iscsi/iscsid.conf <<EOF
node.session.auth.authmethod = CHAP
node.session.auth.username = 5f84cec2
node.session.auth.password = b0d324e9
EOF

systemctl enable iscsid
systemctl start iscsid
```
After you have done the target setup, you should have got the iscsi-target pod ip, let's assume the ip is *10.2.0.2* iscsiadm -m discovery -t sendtargets -p on every node of your cluster run:

```
iscsiadm -m discovery -t sendtargets -p 10.2.0.2
iscsiadm -m node --login
```

You should be able to successfully login.

# Creating test pod

After you have finished the setup for initiator, run `oc create -f pod.json`, you should be able to see your pod in `Running` status.

## Issues

Sometimes, I don't know why, the node just can not discover the target, the work around here is run `targetcli` on the node, delete the host and ip from portals directory, then recreate it, maybe I need to test it more. Will try to fix this issue later.
