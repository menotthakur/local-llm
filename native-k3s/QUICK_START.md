# Quick Start - Native k3s with GPU

## 🚀 Super Simple Setup

1. **Go to the directory:**
   ```bash
   cd native-k3s
   ```

2. **Run the install script:**
   ```bash
   sudo ./install.sh
   ```

That's it! k3s will be installed with GPU support.

## 📝 What Happens

The script will:
- ✅ Detect your NVIDIA GPU
- ✅ Install NVIDIA Container Toolkit
- ✅ Install k3s directly on Ubuntu
- ✅ Configure GPU support
- ✅ Install NVIDIA Device Plugin
- ✅ Set up kubectl and kubeconfig

## ✅ Verify It Works

```bash
# Check k3s is running
sudo systemctl status k3s

# Check your node (should show your Ubuntu machine)
kubectl get nodes

# Check GPU is available
kubectl describe nodes | grep -i gpu

# You should see: nvidia.com/gpu: 1
```

## 🎯 Test GPU Pod

```bash
cat <<EOF | kubectl apply -f -
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

You should see your GPU info!

## 📁 Project Structure

```
native-k3s/
├── install.sh            # Main install script (just run this!)
├── README.md             # Full documentation
└── NATIVE_K3S_GPU_GUIDE.md  # Manual step-by-step guide
```

## 🔧 Script Options

```bash
# Skip GPU setup
sudo ./install.sh --no-gpu

# Show help
sudo ./install.sh --help
```

## 🆘 Troubleshooting

### k3s not starting?
```bash
sudo journalctl -u k3s -f
```

### GPU not showing?
```bash
# Check NVIDIA drivers
nvidia-smi

# Check device plugin
kubectl get pods -n kube-system | grep nvidia

# Check device plugin logs
kubectl logs -n kube-system -l name=nvidia-device-plugin-ds --tail=20
```

## 📚 Learn More

- See `README.md` for full documentation
- See `NATIVE_K3S_GPU_GUIDE.md` for manual installation steps
- See `FIX_GPU.md` for GPU troubleshooting
