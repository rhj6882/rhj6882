### Master step 1 ###
echo "Master step 1"
chmod 600 /etc/kubernetes/manifests/kube-apiserver.yaml
chmod 600 /etc/kubernetes/manifests/kube-controller-manager.yaml
chmod 600 /etc/kubernetes/manifests/kube-scheduler.yaml
chmod 600 /etc/kubernetes/manifests/etcd.yaml
chmod 700 /var/lib/etcd
chmod 600 /etc/kubernetes/admin.conf
chmod 600 /etc/kubernetes/scheduler.conf
chmod 600 /etc/kubernetes/controller-manager.conf
chmod -R 600 /etc/kubernetes/pki/*.crt
chmod -R 600 /etc/kubernetes/pki/*.key
chmod 600 /etc/systemd/system/kubelet.service.d/kubeadm.conf
chmod 600 /etc/kubernetes/kubelet.conf
chmod 600 /etc/kubernetes/bootstrap-kubelet.conf
chmod 600 /etc/kubernetes/pki/ca.crt
##chmod 600 <path/to/cni/files> CNI interface file route

echo "Master step 2"
chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml
chown root:root /etc/kubernetes/manifests/kube-controller-manager.yaml
chown root:root /etc/kubernetes/manifests/kube-scheduler.yaml
chown root:root /etc/kubernetes/manifests/etcd.yaml
chown root:root <path/to/cni/files> CNI interface file route
chown etcd:etcd /var/lib/etcd
chown root:root /etc/kubernetes/admin.conf
chown root:root /etc/kubernetes/scheduler.conf
chown root:root /etc/kubernetes/controller-manager.conf
chown -R root:root /etc/kubernetes/pki/
chown root:root /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "Master step 3"
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/modsecurity/modsecurity.conf
sed -i 's/anonymous-auth=true/anonymous-auth=false/g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/--authorization-mode=AlwaysAllow/--authorization-mode=RBAC/g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/--profiling=true/--profiling=false/g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/--request-timeout=60/--request-timeout=300/g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/--service-account-lookup=false/--service-account-lookup=true/g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/--terminated-pod-gc-threshold=12500/--terminated-pod-gc-threshold=10/g' /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -i 's/--profiling=true/--profiling=false/g' /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -i 's/--use-service-account-credentials=false/--use-service-account-credentials=true/g' /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -i 's/--profiling=true/--profiling=false/g' /etc/kubernetes/manifests/scheduler.conf
sed -i 's/--client-cert-auth='false'/--client-cert-auth='true'/g' /etc/kubernetes/manifests/etcd.yaml
sed -i 's/--peer-client-cert-auth=false/--peer-client-cert-auth=true/g' /etc/kubernetes/manifests/etcd.yaml
sed -i 's/--peer-client-cert-auth=false/--peer-client-cert-auth=true/g' /etc/kubernetes/manifests/etcd.yaml

echo "Master finish"
