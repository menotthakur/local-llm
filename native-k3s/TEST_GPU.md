# Quick Test - GPU Setup

## Current Status Check

1. **Check if k3s detected NVIDIA runtime:**
   ```bash
   grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
   ```
   ✅ Should show nvidia runtime configuration

2. **Check if device plugin is installed:**
   ```bash
   kubectl get daemonset -n kube-system nvidia-device-plugin-daemonset
   ```

3. **Check GPU on host:**
   ```bash
   nvidia-smi
   ```
   ✅ Should show your GPU

## Install/Reinstall Device Plugin

If the device plugin is not installed or needs to be reinstalled:

```bash
# Delete existing (if any)
kubectl delete daemonset -n kube-system nvidia-device-plugin-daemonset --ignore-not-found

# Apply the corrected manifest
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nvidia-device-plugin-daemonset
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: nvidia-device-plugin-ds
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        name: nvidia-device-plugin-ds
    spec:
      runtimeClassName: nvidia
      tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
      priorityClassName: "system-node-critical"
      containers:
      - image: nvcr.io/nvidia/k8s-device-plugin:v0.14.1
        name: nvidia-device-plugin-ctr
        args: ["--fail-on-init-error=false"]
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        volumeMounts:
        - name: device-plugin
          mountPath: /var/lib/kubelet/device-plugins
        env:
        - name: NVIDIA_VISIBLE_DEVICES
          value: all
        - name: NVIDIA_DRIVER_CAPABILITIES
          value: all
      volumes:
      - name: device-plugin
        hostPath:
          path: /var/lib/kubelet/device-plugins
      nodeSelector:
        kubernetes.io/arch: amd64
EOF
```

## Verify After Installation

1. **Check device plugin logs:**
   ```bash
   kubectl logs -n kube-system -l name=nvidia-device-plugin-ds --tail=20
   ```
   Should NOT show "could not load NVML library" error

2. **Check GPU resources:**
   ```bash
   kubectl describe nodes | grep -i "nvidia.com/gpu"
   ```
   Should show: `nvidia.com/gpu: 1`

3. **Test GPU pod:**
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: gpu-test
   spec:
     restartPolicy: Never
     runtimeClassName: nvidia
     containers:
     - name: cuda-container
       image: nvidia/cuda:11.0.3-base-ubuntu20.04
       command: ["nvidia-smi"]
       resources:
         limits:
           nvidia.com/gpu: 1
       env:
       - name: NVIDIA_VISIBLE_DEVICES
         value: all
       - name: NVIDIA_DRIVER_CAPABILITIES
         value: all
   EOF
   
   # Wait a moment, then check logs
   kubectl logs gpu-test
   ```

## Troubleshooting

If GPU still not showing:

1. **Check k3s service:**
   ```bash
   sudo systemctl status k3s
   ```

2. **Check containerd config:**
   ```bash
   grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
   ```

3. **Check device plugin:**
   ```bash
   kubectl describe daemonset -n kube-system nvidia-device-plugin-daemonset
   kubectl logs -n kube-system -l name=nvidia-device-plugin-ds
   ```

4. **Restart k3s if needed:**
   ```bash
   sudo systemctl restart k3s
   sleep 10
   kubectl get nodes
   ```
