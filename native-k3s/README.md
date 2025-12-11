# Native k3s Installation with GPU Support

This project provides scripts and documentation to install k3s **directly on your Ubuntu machine** (not in Docker) with full GPU support. This is the **best way to learn GPU workloads** in Kubernetes.

## What This Does

- Installs k3s directly on Ubuntu (single node: control plane + worker)
- Configures NVIDIA Container Toolkit for GPU support
- Sets up containerd with NVIDIA runtime
- Installs NVIDIA Device Plugin automatically
- Tests GPU access with a sample pod

## Why Native k3s?

- ✅ **Full GPU Support**: Direct access to your GPU (no Docker layer)
- ✅ **Simple Setup**: Follows official k3s documentation
- ✅ **Real-World**: Matches production setups
- ✅ **Easy to Learn**: Clear, straightforward configuration

## Quick Start

### Option 1: Automated Install Script

```bash
cd native-k3s
sudo ./install.sh
```

That's it! k3s will be installed with GPU support.

**Options:**
- `--no-gpu` - Skip GPU setup (install k3s only)
- `--help` - Show help message

### Option 2: Manual Installation

Follow the step-by-step guide in [NATIVE_K3S_GPU_GUIDE.md](NATIVE_K3S_GPU_GUIDE.md).

## Project Structure

```
native-k3s/
├── install.sh                  # ⭐ Main installation script
├── README.md                   # This file
├── QUICK_START.md              # Quick reference
├── NATIVE_K3S_GPU_GUIDE.md     # Detailed manual guide
├── FIX_GPU.md                  # GPU troubleshooting
├── TEST_GPU.md                 # GPU testing guide
└── GLOSSARY_AND_DICTIONARY.md  # Terminology reference
```

## What Gets Installed

1. **Prerequisites**: curl, wget
2. **NVIDIA Container Toolkit** (if NVIDIA GPU detected)
3. **k3s**: Latest version
4. **kubectl**: Kubernetes CLI tool (via k3s)
5. **NVIDIA Device Plugin**: Automatically installed if GPU detected

## Verification

After installation:

```bash
# Check k3s is running
sudo systemctl status k3s

# Check nodes (should show your Ubuntu machine)
kubectl get nodes

# Check GPU (if enabled)
kubectl describe nodes | grep -i gpu

# Check all pods
kubectl get pods --all-namespaces
```

## GPU Testing

The install script automatically sets up GPU support. You can test manually:

```bash
# Create a GPU pod (note: runtimeClassName is required for k3s!)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
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

> **⚠️ Important for k3s:** Always use `runtimeClassName: nvidia` for GPU workloads. k3s keeps `runc` as the default runtime, unlike standard Kubernetes where NVIDIA runtime might be the default on GPU nodes.

## Managing k3s

### Check Status
```bash
sudo systemctl status k3s
```

### Stop k3s
```bash
sudo systemctl stop k3s
```

### Start k3s
```bash
sudo systemctl start k3s
```

### Uninstall k3s
```bash
/usr/local/bin/k3s-uninstall.sh
```

## Adding More Nodes (Optional)

You can add VMs or other machines as worker nodes:

1. On the new machine, install k3s-agent:
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<token> sh -
```

2. Get the token from the server:
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

## Differences from k3d

| Feature | k3d | Native k3s |
|---------|-----|------------|
| Installation | In Docker containers | Direct on host |
| GPU Support | Complex (containerd config) | Simple (direct access) |
| Resource Usage | Higher (Docker overhead) | Lower (direct) |
| Use Case | Learning multi-node | Learning GPU workloads |

## Troubleshooting

### k3s Service Not Starting
```bash
sudo journalctl -u k3s -f
```

### GPU Not Detected
```bash
# Check NVIDIA drivers
nvidia-smi

# Check k3s containerd config (note the path!)
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml

# Check device plugin
kubectl get pods -n kube-system | grep nvidia

# Check device plugin logs
kubectl logs -n kube-system -l name=nvidia-device-plugin-ds --tail=20
```

**Common issues:**
- Device plugin can't find NVML library → Missing `runtimeClassName: nvidia` in device plugin manifest
- "read-only file system" error → Remove library volume mount (not needed with `runtimeClassName: nvidia`)
- See `FIX_GPU.md` for detailed troubleshooting

### kubectl Not Working
```bash
# Check kubeconfig
cat ~/.kube/config

# Test connection
kubectl cluster-info
```

## Next Steps

1. **Learn GPU Workloads**: Create pods that use GPU
2. **Resource Management**: Practice GPU requests/limits
3. **Monitoring**: Monitor GPU usage
4. **Add Nodes**: Join VMs as worker nodes (optional)

## Resources

- [k3s Documentation](https://docs.k3s.io/)
- [k3s NVIDIA Runtime](https://docs.k3s.io/advanced#nvidia-container-runtime)
- [NVIDIA Device Plugin](https://github.com/NVIDIA/k8s-device-plugin)
