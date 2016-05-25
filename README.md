ISCSI target pod for OpenShift testings.

# Target Setup
ISCSI target setup needs to run a privileged container with `SYS_MODULE` capability and `/lib/modules` mount directory. First edit the scc.yml, replace `YOUR_USERNAME` with your OpenShift login, then run:

```
oc create -f scc.yml
oc create -f iscsi-target.yml
```

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
echo 'InitiatorName=iqn.2016-04.test.com:test.img' > /etc/iscsi/initiatorname.iscsi

cat >> /etc/iscsi/iscsid.conf <<EOF
node.session.auth.authmethod = CHAP
node.session.auth.username = 5f84cec2
node.session.auth.password = b0d324e9
EOF

systemctl enable iscsid
systemctl start iscsid
```

## Using iscsi-target podIP
After you have completed the target setup, you should have got the iscsi-target pod ip, let's assume the ip is *10.2.0.2*, then on every node of your cluster run:

```
iscsiadm -m discovery -t sendtargets -p 10.2.0.2
iscsiadm -m node -p 10.2.0.2:3260 -T iqn.2016-04.test.com:storage.target00 -I default --login
```

You should be able to successfully login.

## Using service instead of podIP

you could also use a service ip instead of podIP.

\1. Create the service

```
oc create -f service.json
```

\2. Get the service ip `oc get serivce iscsi-target`, assume the ip is `172.30.50.235`.

\3. Create a portal in the `iscsi-target` pod using the service ip

```
oc exec iscsi-target -- targetcli /iscsi/iqn.2016-04.test.com:storage.target00/tpg1/portals create 172.30.50.235
```

\4. On nodes, configure iscsi initiator with the service ip

```
iscsiadm -m discovery -t sendtargets -p 172.30.50.235
iscsiadm -m node -p 172.30.50.235:3260 -T iqn.2016-04.test.com:storage.target00 -I default --login
```

# Creating Persistent Volume and Claim

Update your Persistent Volume template, set **targetPortal** to your podIP or service ip.

```
oc create -f pv-rwo.json
oc create -f pvc-rwo.json
oc get pv
oc get pvc
```

You should see PV and PVC are bound to each other.

## Creating tester pod

```
oc create -f pod.json
```

You should see your pod is `Running`.
