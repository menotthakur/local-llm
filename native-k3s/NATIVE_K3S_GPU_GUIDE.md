## Native k3s + NVIDIA GPU – Full Learning Guide

This guide walks you through a **manual, from-scratch setup** of:
- Native **k3s** (no k3d, no Docker cluster)
- **NVIDIA GPU support** using NVIDIA Container Runtime + NVIDIA Device Plugin
- A test GPU pod suitable as a starting point for **AI workloads**

You can delete your existing setup and follow this **line by line**.

---

## Layered Architecture (Mental Model)

```text
+-----------------------------------------------------+
|  AI Workloads (Pods: PyTorch, Jupyter, etc.)        |
+---------------------------+-------------------------+
|  Kubernetes (k3s)         |  NVIDIA Device Plugin   |
+---------------------------+-------------------------+
|  containerd (k3s) using NVIDIA runtime              |
+-----------------------------------------------------+
|  NVIDIA Driver + Libraries (nvidia-smi, NVML)       |
+-----------------------------------------------------+
|  Ubuntu (host OS)                                   |
+-----------------------------------------------------+
```

We will configure **each layer** in order.

---

## 1. Start Clean (Optional but Recommended)

If you already have k3s or a device plugin installed and want a fresh start:

### 1.1 Remove existing k3s

```bash
sudo /usr/local/bin/k3s-uninstall.sh || echo "k3s not installed (ok)"
```

- Removes the k3s service, data directories, and binaries.

### 1.2 Remove any existing NVIDIA device plugin

```bash
kubectl delete daemonset -n kube-system nvidia-device-plugin-daemonset --ignore-not-found
```

- Ensures we will install a **fresh** device plugin later.

---

## 2. Verify NVIDIA Drivers on the Host

Before touching Kubernetes, make sure the **host** GPU stack is healthy.

### 2.1 Check `nvidia-smi`

```bash
nvidia-smi
```

You should see:
- Your GPU (e.g. `NVIDIA GeForce RTX 3060 Laptop GPU`)
- Driver version
- CUDA version

If this fails, fix your drivers first (Ubuntu "Additional Drivers" or NVIDIA docs).

### 2.2 Confirm NVML library exists

```bash
ls -l /usr/lib/x86_64-linux-gnu/libnvidia-ml.so*
```

You should see symlinks like:

```text
libnvidia-ml.so   -> libnvidia-ml.so.1
libnvidia-ml.so.1 -> libnvidia-ml.so.XXX
```

The **NVIDIA Device Plugin** uses this NVML library to detect GPUs.

---

## 3. Install NVIDIA Container Runtime

k3s will automatically detect alternative runtimes like **nvidia** when they are present in `PATH`, as described in the k3s docs ([Advanced → NVIDIA Container Runtime](https://docs.k3s.io/advanced#nvidia-container-runtime)).

### 3.1 Add NVIDIA libnvidia-container repository

```bash
# Add NVIDIA GPG key
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Add the stable repository
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

> **⚠️ Common Issue:** If you get a 404 HTML page or "Unsupported distribution" error, check the URL. The correct URL is `nvidia-container-toolkit.list` (not `libnvidia-container.list` or `/amd64/libnvidia-container.list`). If you see HTML in your sources list, remove it: `sudo rm /etc/apt/sources.list.d/nvidia-container-toolkit.list` and try again.

### 3.2 Install `nvidia-container-runtime`

```bash
sudo apt update
sudo apt install -y nvidia-container-runtime
```

This installs the `nvidia-container-runtime` binary so k3s/containerd can use it.

> **⚠️ If `apt update` fails** with "Type '<!doctype' is not known", you have HTML in your sources list. Remove the bad file: `sudo rm /etc/apt/sources.list.d/nvidia-container-toolkit.list` and re-run section 3.1.

### 3.3 Verify the runtime is in PATH

```bash
which nvidia-container-runtime
```

Expected output:

```text
/usr/bin/nvidia-container-runtime
```

If this is present, k3s will detect it on startup.

---

## 4. Install k3s (Single-Node Cluster)

We now install k3s directly on Ubuntu (no Docker cluster).

### 4.1 Install latest k3s

```bash
curl -sfL https://get.k3s.io | sudo sh -
```

This will:
- Install the `k3s` binary to `/usr/local/bin/k3s`
- Create and start the `k3s` systemd service
- Configure built-in `containerd`, CNI, CoreDNS, etc.

### 4.2 Check k3s status

```bash
sudo systemctl status k3s
```

Look for:
- `Active: active (running)`

If not, inspect logs with:

```bash
sudo journalctl -u k3s -f
```

### 4.3 Configure kubeconfig for your user

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER":"$USER" ~/.kube/config

# Optional: replace 127.0.0.1 with localhost
sed -i 's/127\.0\.0\.1/localhost/g' ~/.kube/config
```

Then test:

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

You should see your node `Ready` and system pods running.

---

## 5. Verify k3s Detected the NVIDIA Runtime

k3s should now have added a `nvidia` runtime to its internal containerd config.

### 5.1 Inspect containerd config for NVIDIA

```bash
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

> **💡 Note:** The config file is at `/var/lib/rancher/k3s/agent/etc/containerd/config.toml`, NOT in `/var/lib/rancher/k3s/agent/containerd/` (that's the runtime state directory).

Look for entries like:

```toml
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'nvidia']
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.'nvidia'.options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
```

This confirms that:
- There is a `nvidia` runtime configured.
- It uses `nvidia-container-runtime` as the underlying binary.

> **💡 How it works:** k3s automatically detects `nvidia-container-runtime` in PATH during startup and adds it to the containerd config. No manual configuration needed!

---

## 6. Install NVIDIA Device Plugin

Now we teach Kubernetes about GPUs using the NVIDIA Device Plugin.

> **⚠️ Important for k3s:** The default NVIDIA device plugin manifest from GitHub does NOT include `runtimeClassName: nvidia`, which is **required** for k3s. Use the corrected manifest below.

### 6.1 Apply NVIDIA Device Plugin DaemonSet (k3s-compatible)

**Do NOT use the default GitHub manifest** - it won't work with k3s. Use this corrected version:

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

> **🔑 Key Differences from Default Manifest:**
> - ✅ **`runtimeClassName: nvidia`** - Required for k3s! Without this, the device plugin container uses the default `runc` runtime and can't access GPU libraries.
> - ✅ **No library volume mount** - The NVIDIA runtime automatically injects libraries when `runtimeClassName: nvidia` is set. Mounting `/usr/lib/x86_64-linux-gnu` as read-only causes symlink conflicts.
> - ✅ **`--fail-on-init-error=false`** - Prevents pod crashes during troubleshooting.

> **❓ Why doesn't the default manifest work?**
> - Standard Kubernetes (kubeadm, EKS, GKE) often sets NVIDIA runtime as the **default** on GPU nodes, so `runtimeClassName` is optional.
> - **k3s keeps `runc` as default** and requires explicit `runtimeClassName: nvidia` for GPU workloads.
> - This is a k3s design decision for simplicity and compatibility.

### 6.2 Check the plugin pod

```bash
kubectl get pods -n kube-system | grep nvidia
```

You want to see a pod like:

```text
nvidia-device-plugin-daemonset-xxxxx   1/1   Running   0   <age>
```

### 6.3 Inspect device plugin logs

```bash
kubectl logs -n kube-system -l name=nvidia-device-plugin-ds --tail=20
```

**Good signs:**
- `Detected NVML platform: found NVML library`
- `Registered device plugin for 'nvidia.com/gpu' with Kubelet`

**Bad signs (if you see these, check troubleshooting below):**
- `could not load NVML library: libnvidia-ml.so.1: cannot open shared object file` → Missing `runtimeClassName: nvidia`
- `failed to create symlink: read-only file system` → Library mount conflict (remove the mount)

This means the plugin successfully loaded NVML and registered the GPU resource.

---

## 7. Confirm GPU Resources on the Node

### 7.1 Describe node and look for `nvidia.com/gpu`

```bash
kubectl describe nodes | grep -B 2 -A 2 "nvidia.com/gpu"
```

> **💡 `-B 2 -A 2` means:** Show 2 lines before (`-B`) and 2 lines after (`-A`) the match for context.

You should see output like:

```text
Capacity:
  ...
  nvidia.com/gpu:     1
Allocatable:
  ...
  nvidia.com/gpu:     1
...
Allocated resources:
  ...
  nvidia.com/gpu      0           0
```

This means Kubernetes now knows you have 1 GPU available.

---

## 8. Run a Test GPU Pod (AI "Hello World")

The final verification: run `nvidia-smi` **inside a pod**.

### 8.1 Why `runtimeClassName: nvidia` is required

From the k3s documentation:

> If you have not changed the default runtime on your GPU nodes, you must explicitly request the NVIDIA runtime by setting `runtimeClassName: nvidia` in the Pod spec.

So we **must** set:

```yaml
runtimeClassName: nvidia
```

### 8.2 Create the test pod

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
```

Wait a few seconds, then check logs:

```bash
kubectl logs gpu-test
```

You should see GPU information from `nvidia-smi` running **inside the container**!

### 8.3 GPU Stress Test with PyTorch (Optional)

For a more realistic GPU workload test using PyTorch:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gpu-stress
spec:
  restartPolicy: Never
  runtimeClassName: nvidia
  containers:
  - name: stress
    image: pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime
    command: 
    - python
    - -c
    - |
      import torch
      import time
      
      print('Starting GPU stress test...')
      print('GPU:', torch.cuda.get_device_name(0))
      
      # Large matrix operations to stress GPU
      for i in range(10):
          size = 8000
          a = torch.randn(size, size).cuda()
          b = torch.randn(size, size).cuda()
          
          start = time.time()
          c = torch.matmul(a, b)
          torch.cuda.synchronize()
          elapsed = time.time() - start
          
          print(f'Iteration {i+1}: {elapsed:.3f}s, Memory: {torch.cuda.memory_allocated(0)/1e9:.2f}GB')
      
      print('Stress test complete!')
    resources:
      limits:
        nvidia.com/gpu: 1
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      value: all
    - name: NVIDIA_DRIVER_CAPABILITIES
      value: all
EOF
```

> **💡 Note:** The `|` after `-c` preserves newlines in the Python code. Without it, all Python statements would be on one line, causing syntax errors.

Monitor the stress test:

```bash
# Watch pod status
kubectl get pods -w

# Check logs
kubectl logs -f gpu-stress

# Monitor GPU on host (in another terminal)
watch -n 1 nvidia-smi
```

---

## Troubleshooting

### Issue: Repository URL returns 404 HTML page

**Symptoms:**
- `curl` returns HTML instead of repository list
- `apt update` fails with "Type '<!doctype' is not known"

**Solution:**
```bash
# Remove the bad sources file
sudo rm /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Re-run section 3.1 with the correct URL
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

### Issue: Device plugin can't find NVML library

**Symptoms:**
- Logs show: `could not load NVML library: libnvidia-ml.so.1: cannot open shared object file`
- Device plugin pod is `Running` but GPU resources don't appear

**Solution:**
The device plugin manifest is missing `runtimeClassName: nvidia`. Delete and reapply with the corrected manifest from section 6.1.

### Issue: Device plugin fails with "read-only file system" error

**Symptoms:**
- Logs show: `failed to create symlink: read-only file system`
- Pod is in `CrashLoopBackOff`

**Solution:**
You're mounting `/usr/lib/x86_64-linux-gnu` as read-only, which conflicts with NVIDIA runtime's symlink creation. Remove the library mount - it's not needed when using `runtimeClassName: nvidia`.

### Issue: Can't find containerd config file

**Symptoms:**
- `grep nvidia /var/lib/rancher/k3s/agent/containerd/config.toml` fails

**Solution:**
The config is at `/var/lib/rancher/k3s/agent/etc/containerd/config.toml` (note the `etc/` directory), not in `/var/lib/rancher/k3s/agent/containerd/`.

### Issue: Python script in pod fails with syntax errors

**Symptoms:**
- Pod exits with `Exit Code: 1`
- Logs show Python syntax errors like "invalid syntax"
- Python code appears concatenated on one line

**Solution:**
When using multi-line Python code in a pod's `command` field, use the `|` (pipe) YAML literal block scalar to preserve newlines:

```yaml
command: 
- python
- -c
- |
  import torch
  import time
  print('Hello')
```

**Wrong way** (all code on one line):
```yaml
command: ["python", "-c", "import torch import time print('Hello')"]
```

**Correct way** (preserves newlines):
```yaml
command: 
- python
- -c
- |
  import torch
  import time
  print('Hello')
```

---

## Summary

You now have:
- ✅ Native k3s cluster running
- ✅ NVIDIA Container Runtime detected by k3s
- ✅ NVIDIA Device Plugin registered and working
- ✅ GPU resources visible in Kubernetes
- ✅ Test GPU pod running successfully

Next steps: Deploy your AI workloads (PyTorch, Jupyter, TensorFlow, etc.) using `runtimeClassName: nvidia` and `nvidia.com/gpu` resource limits!
