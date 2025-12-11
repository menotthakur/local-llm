# K3s AI Workloads

Running AI workloads on Kubernetes with GPU acceleration using k3s.

## Projects

| Project | Description |
|---------|-------------|
| [**ai-workloads/**](ai-workloads/) | Ollama + Open-webui deployment (manifests + Ansible) |
| [**native-k3s/**](native-k3s/) | k3s installation with GPU support |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser                                  │
│                           │                                     │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 Open-webui (Port 8080)                  │    │
│  │                   ChatGPT-like UI                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                     │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                  Ollama (Port 11434)                    │    │
│  │              LLM Server with GPU Support                │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                     │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              k3s + NVIDIA Container Runtime             │    │
│  │                  (runtimeClassName: nvidia)             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                     │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    NVIDIA GPU                           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Setup k3s with GPU

```bash
cd native-k3s
sudo ./install.sh
```

### 2. Deploy AI Stack

```bash
cd ai-workloads

# Using kubectl
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/ollama/
kubectl apply -f manifests/open-webui/

# Or using Ansible
cd ansible && ansible-playbook playbook.yml
```

### 3. Access

```bash
# Pull a model
kubectl exec -n ollama deployment/ollama -- ollama pull llama3.2:1b

# Port forward
kubectl port-forward -n ollama svc/open-webui 8080:8080

# Open browser: http://localhost:8080
```

## Tech Stack

- **k3s** - Lightweight Kubernetes
- **Ollama** - Local LLM inference
- **Open-webui** - Web interface for LLMs
- **NVIDIA Container Runtime** - GPU passthrough
- **Persistent Volumes** - Data persistence

## Key Features

- GPU-accelerated LLM inference
- Self-hosted (no cloud dependency)
- Persistent storage for models and data
- Health checks (liveness + readiness probes)
- Clean Kubernetes manifests
- Ansible automation option

## Requirements

- Ubuntu with NVIDIA GPU
- NVIDIA drivers installed
- Docker (optional, for k3d)

## Directory Structure

```
K3s-stuff/
├── README.md                 # This file
├── ai-workloads/             # AI stack deployment
│   ├── manifests/            # Kubernetes YAML
│   └── ansible/              # Ansible automation
├── native-k3s/               # k3s + GPU setup
│   ├── install.sh            # Installation script
│   └── docs/                 # Guides
├── Ollama/                   # Legacy manifests
└── Open-webui/               # Legacy manifests
```

## Resources

- [k3s Documentation](https://docs.k3s.io/)
- [Ollama](https://ollama.ai/)
- [Open-webui](https://github.com/open-webui/open-webui)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
