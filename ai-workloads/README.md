# AI Workloads on Kubernetes

Self-hosted AI stack running on k3s with GPU acceleration.

## Stack

| Component | Description | Port |
|-----------|-------------|------|
| **Ollama** | LLM inference server with GPU | 11434 |
| **Open-webui** | ChatGPT-like web interface | 8080 |

## Architecture

```
Browser --> Open-webui (8080) --> Ollama (11434) --> NVIDIA GPU
                |                      |
            PVC (5Gi)              PVC (10Gi)
```

## Prerequisites

- k3s cluster with GPU support (see `native-k3s/` for setup)
- NVIDIA GPU with drivers installed
- `nvidia-container-runtime` in PATH
- kubectl configured

## Quick Start

### Option 1: kubectl (Manual)

```bash
# Create namespace and deploy
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/ollama/
kubectl apply -f manifests/open-webui/

# Wait for pods
kubectl wait --for=condition=ready pod -l app=ollama -n ollama --timeout=120s
kubectl wait --for=condition=ready pod -l app=open-webui -n ollama --timeout=120s

# Pull a model
kubectl exec -n ollama deployment/ollama -- ollama pull llama3.2:1b

# Access UI
kubectl port-forward -n ollama svc/open-webui 8080:8080
# Open http://localhost:8080
```

### Option 2: Ansible (Automated)

```bash
cd ansible

# Install required collection
ansible-galaxy collection install kubernetes.core

# Run playbook
ansible-playbook playbook.yml

# Access UI
kubectl port-forward -n ollama svc/open-webui 8080:8080
```

## Directory Structure

```
ai-workloads/
├── README.md
├── manifests/                    # Kubernetes manifests
│   ├── namespace.yaml
│   ├── ollama/
│   │   ├── pvc.yaml
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── open-webui/
│       ├── pvc.yaml
│       ├── deployment.yaml
│       └── service.yaml
└── ansible/                      # Ansible automation
    ├── ansible.cfg
    ├── inventory.ini
    ├── playbook.yml
    └── roles/
        ├── ollama/
        └── open-webui/
```

## Configuration

### Manifests

Edit the YAML files directly in `manifests/` directory.

### Ansible

Override variables in `ansible/playbook.yml` or create `group_vars/all.yml`:

```yaml
# Ollama settings
ollama_gpu_enabled: true
ollama_gpu_count: 1
ollama_storage_size: "20Gi"
ollama_default_model: "llama3.2:3b"

# Open-webui settings
openwebui_storage_size: "10Gi"
```

## Verification

```bash
# Check pods
kubectl get pods -n ollama

# Check GPU usage
kubectl exec -n ollama deployment/ollama -- nvidia-smi

# Check logs
kubectl logs -n ollama deployment/ollama
kubectl logs -n ollama deployment/open-webui

# List models
kubectl exec -n ollama deployment/ollama -- ollama list
```

## Pull More Models

```bash
# Small models
kubectl exec -n ollama deployment/ollama -- ollama pull tinyllama
kubectl exec -n ollama deployment/ollama -- ollama pull llama3.2:1b

# Medium models
kubectl exec -n ollama deployment/ollama -- ollama pull llama3.2:3b
kubectl exec -n ollama deployment/ollama -- ollama pull mistral

# Code models
kubectl exec -n ollama deployment/ollama -- ollama pull codellama
kubectl exec -n ollama deployment/ollama -- ollama pull deepseek-coder
```

## Cleanup

```bash
# Delete workloads (keeps PVCs/data)
kubectl delete deployment ollama open-webui -n ollama

# Delete everything including data
kubectl delete namespace ollama
```

## Troubleshooting

### GPU not detected

```bash
# Check nvidia-smi on host
nvidia-smi

# Check k3s containerd config
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml

# Check device plugin
kubectl get pods -n kube-system | grep nvidia
kubectl logs -n kube-system -l name=nvidia-device-plugin-ds
```

### Pods stuck pending

```bash
# Check events
kubectl describe pod -n ollama -l app=ollama

# Common issues:
# - Insufficient nvidia.com/gpu (another pod using GPU)
# - PVC not binding (check storage class)
```

### Open-webui can't connect to Ollama

```bash
# Test connectivity
kubectl exec -n ollama deployment/open-webui -- curl -s http://ollama:11434

# Check service
kubectl get svc -n ollama
kubectl get endpoints -n ollama
```

## Resources

- [Ollama](https://ollama.ai/)
- [Open-webui](https://github.com/open-webui/open-webui)
- [k3s NVIDIA Runtime](https://docs.k3s.io/advanced#nvidia-container-runtime)
