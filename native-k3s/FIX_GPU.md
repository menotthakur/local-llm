# Fix GPU Detection in k3s

## Current Status

✅ k3s has detected NVIDIA runtime (check: `grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml`)
❌ Device plugin can't find NVIDIA libraries
❌ GPU resources not showing in nodes

## Quick Fix

### 1. Delete existing device plugin (if needed)
```bash
kubectl delete daemonset -n kube-system nvidia-device-plugin-daemonset
```

### 2. Reinstall the device plugin with correct config

```bash
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

### 3. Wait and verify
```bash
# Wait 30 seconds
sleep 30

# Check device plugin logs
kubectl logs -n kube-system -l name=nvidia-device-plugin-ds --tail=20

# Check GPU resources
kubectl describe nodes | grep -i "nvidia.com/gpu"
```

## What Changed

1. **Added `runtimeClassName: nvidia`** - Required by k3s for GPU workloads. Without this, the device plugin uses the default `runc` runtime and can't access GPU libraries.
2. **No library volume mount** - The NVIDIA runtime automatically injects libraries when `runtimeClassName: nvidia` is set. Mounting `/usr/lib/x86_64-linux-gnu` as read-only causes symlink conflicts.
3. **Added NVIDIA env vars** - Ensures proper GPU access
4. **Added `--fail-on-init-error=false`** - Prevents pod crashes during troubleshooting

> **⚠️ Why no library mount?** When using `runtimeClassName: nvidia`, the NVIDIA container runtime automatically injects the necessary libraries into the container. An explicit mount is not needed and can cause "read-only file system" errors when the runtime tries to create symlinks.

## Test GPU Pod

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

# Check logs
kubectl logs gpu-test
```

## Troubleshooting Steps

### Check NVIDIA drivers on host
```bash
nvidia-smi
```

### Check k3s detected NVIDIA runtime
```bash
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

### Check device plugin status
```bash
kubectl get pods -n kube-system | grep nvidia
kubectl describe daemonset -n kube-system nvidia-device-plugin-daemonset
```

### Check device plugin logs
```bash
kubectl logs -n kube-system -l name=nvidia-device-plugin-ds --tail=50
```

### Restart k3s if needed
```bash
sudo systemctl restart k3s
sleep 10
kubectl get nodes
```
