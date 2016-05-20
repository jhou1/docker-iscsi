ISCSI target pod for OpenShift testings.

# Target Setup
ISCSI target setup needs to run a privileged container with `SYS_MODULE` capability and `/lib/modules` mount directory. First edit the scc.yml, replace `YOUR_USERNAME` with your OpenShift login, then run:

```
oc create -f scc.yml
oc create -f iscsi-target.yml
```

After your pod is created, run `oc get pod iscsi-target -o yaml | grep podIP`, the IP address will be used later for your initiator setup.

## Verify iscsi setup is successful

After pod is `Running`, run `oc exec iscsi-target -- targetcli ls /iscsi/iqn.2016-04.test.com:storage.target00/tpg1`, you should see

```
</iqn.2016-04.test.com:storage.target00/tpg1/portals
o- portals  [Portals: 1]
  o- 10.1.1.3:3260  [OK]
>
```

# Initiator Setup
Initiator must be setup properly on every node of your cluster, run the following commands on your nodes:

```
yum -y install iscsi-initiator-utils # Normally this isn't needed because installation already had it done

echo 'InitiatorName=iqn.2016-04.test.com:test.img' > /etc/iscsi/initiatorname.iscsi

cat >> /etc/iscsi/iscsid.conf <<EOF
node.session.auth.authmethod = CHAP
node.session.auth.username = 5f84cec2
node.session.auth.password = b0d324e9
EOF

systemctl enable iscsid
systemctl start iscsid
```

After you have completed the target setup, you should have got the iscsi-target pod ip, let's assume the ip is *10.2.0.2*, then on every node of your cluster run:

```
iscsiadm -m discovery -t sendtargets -p 10.2.0.2
iscsiadm -m node -p 10.2.0.2:3260 -T iqn.2016-04.test.com:storage.target00 -I default --login
```

You should be able to successfully login.

# Making tests

## Creating Persistent Volume and Claim

Update your Persistent Volume template, replace `#POD_IP#` with the iscsi-target pod ip. eg

```
sed -i s/#POD_IP#/10.2.0.2/ pv-rwo.json
oc create -f pv-rwo.json
oc create -f pvc-rwo.json
```

## Creating tester pod

```
oc create -f pod.json
```

Once your pod is `Running`, run `oc exec -it iscsi -- sh`, you should be able to access the mount dir `/mnt/iscsci`
