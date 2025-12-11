# Glossary & Dictionary - k3s + GPU Learning Reference

> **Quick Reference Guide** - Key definitions, terminology, and important concepts from your k3s + GPU setup journey.

---

## Table of Contents

1. [Kubernetes Terms](#kubernetes-terms)
2. [k3s Terms](#k3s-terms)
3. [GPU & NVIDIA Terms](#gpu--nvidia-terms)
4. [Container Terms](#container-terms)
5. [Docker Terms](#docker-terms)
6. [Linux Commands](#linux-commands)
7. [Key Concepts & Mental Models](#key-concepts--mental-models)
8. [Important Points to Remember](#important-points-to-remember)

---

## Kubernetes Terms

| Term | Definition |
|------|------------|
| **Kubernetes (K8s)** | Container orchestration platform that automates deployment, scaling, and management of containerized applications |
| **kubectl** | Command-line tool for interacting with Kubernetes clusters (`kubectl get nodes`, `kubectl apply -f`) |
| **Node** | A worker machine in Kubernetes (can be physical or virtual) |
| **Control Plane** | The "brain" of Kubernetes - manages the cluster, schedules pods, maintains desired state |
| **Worker Node** | A node that runs your application workloads (pods) |
| **Pod** | Smallest deployable unit in Kubernetes - contains one or more containers that share storage/network |
| **Deployment** | Kubernetes object that manages a set of identical pods (handles scaling, updates, rollbacks) |
| **DaemonSet** | Ensures a copy of a pod runs on every node (e.g., NVIDIA Device Plugin) |
| **Service** | Network abstraction that provides stable IP/name to access pods |
| **Namespace** | Virtual cluster within a physical cluster (isolates resources) |
| **kubeconfig** | Configuration file that tells `kubectl` which cluster to connect to (`~/.kube/config`) |
| **Runtime Class** | Specifies which container runtime to use for a pod (e.g., `runtimeClassName: nvidia`) |
| **Device Plugin** | Extends Kubernetes to advertise hardware resources (like GPUs) to the scheduler |
| **Resource Limits** | Maximum CPU/memory/GPU a pod can use (`resources.limits.nvidia.com/gpu: 1`) |
| **Resource Requests** | Minimum CPU/memory/GPU a pod needs (`resources.requests`) |
| **Scheduler** | Kubernetes component that decides which node a pod should run on |
| **Kubelet** | Agent running on each node that manages pods and communicates with control plane |

---

## k3s Terms

| Term | Definition |
|------|------------|
| **k3s** | Lightweight Kubernetes distribution - single binary, easy to install, production-ready |
| **k3d** | Tool to run k3s clusters in Docker containers (for testing/development) |
| **Native k3s** | k3s installed directly on the host OS (not in containers) - best for GPU workloads |
| **containerd** | Container runtime that k3s uses internally (replaces Docker in k3s) |
| **CNI** | Container Network Interface - handles pod networking (k3s includes Flannel by default) |
| **CoreDNS** | DNS server for Kubernetes (k3s includes it automatically) |
| **Single-Node Cluster** | One machine running both control plane and worker roles (common in k3s) |
| **k3s-agent** | Worker node component - connects to k3s server using a token |
| **k3s server** | Control plane component - manages the cluster |
| **k3s.yaml** | kubeconfig file created by k3s (`/etc/rancher/k3s/k3s.yaml`) |

---

## GPU & NVIDIA Terms

| Term | Definition |
|------|------------|
| **GPU (Graphics Processing Unit)** | Hardware specialized for parallel processing (great for AI/ML workloads) |
| **CUDA** | NVIDIA's parallel computing platform - lets programs use GPU for computation |
| **nvidia-smi** | Command-line tool to monitor NVIDIA GPU status, temperature, memory, processes |
| **NVML (NVIDIA Management Library)** | Library that provides APIs for GPU management (used by nvidia-smi and device plugin) |
| **NVIDIA Driver** | Software that allows OS to communicate with NVIDIA GPU hardware |
| **NVIDIA Container Runtime** | Container runtime that enables GPU access inside containers |
| **NVIDIA Container Toolkit** | Collection of tools including nvidia-container-runtime |
| **NVIDIA Device Plugin** | Kubernetes DaemonSet that advertises GPUs to the scheduler |
| **nvidia.com/gpu** | Kubernetes resource name for NVIDIA GPUs (visible in `kubectl describe nodes`) |
| **NVIDIA_VISIBLE_DEVICES** | Environment variable that controls which GPUs a container can see |
| **NVIDIA_DRIVER_CAPABILITIES** | Environment variable that controls which driver features are available |
| **CUDA Version** | Version of CUDA toolkit (shown in `nvidia-smi` output) |
| **Driver Version** | Version of NVIDIA driver installed (shown in `nvidia-smi` output) |
| **libnvidia-ml.so** | Shared library file for NVML (located in `/usr/lib/x86_64-linux-gnu/`) |

---

## Container Terms

| Term | Definition |
|------|------------|
| **Container** | Lightweight, isolated environment that packages an application and its dependencies |
| **Container Runtime** | Software that runs containers (containerd, Docker, nvidia-container-runtime) |
| **Container Image** | Read-only template used to create containers (e.g., `nvidia/cuda:11.0.3-base`) |
| **Dockerfile** | Text file with instructions to build a container image |
| **Registry** | Repository for storing container images (Docker Hub, NVIDIA NGC, etc.) |
| **OCI (Open Container Initiative)** | Standards for container formats and runtimes |
| **Volume Mount** | Way to share files/directories between host and container |
| **Environment Variables** | Key-value pairs passed to containers (e.g., `NVIDIA_VISIBLE_DEVICES=all`) |

---

## Docker Terms

| Term | Definition |
|------|------------|
| **Docker** | Platform for developing, shipping, and running containers |
| **Docker Engine** | Runtime that builds and runs containers |
| **Docker Compose** | Tool for defining and running multi-container applications |
| **Dockerfile** | Instructions to build a Docker image |
| **Image** | Read-only template for creating containers |
| **Container** | Running instance of an image |
| **Docker Hub** | Public registry for Docker images |
| **Volume** | Persistent storage for containers |
| **Network** | Isolated network for containers to communicate |
| **docker ps** | List running containers |
| **docker exec** | Run a command in a running container |
| **docker logs** | View logs from a container |

---

## Linux Commands

| Command | Purpose | Example |
|---------|---------|---------|
| **chown** | Change file/directory ownership | `chown user:group file` |
| **chmod** | Change file permissions | `chmod 777 file` (read/write/execute for all) |
| **curl** | Download files from URLs | `curl -sfL https://get.k3s.io` |
| **grep** | Search text in files/output | `grep nvidia file.txt` |
| **sed** | Stream editor for text manipulation | `sed -i 's/old/new/g' file` |
| **which** | Find location of a command | `which kubectl` |
| **systemctl** | Manage systemd services | `systemctl status k3s` |
| **journalctl** | View systemd logs | `journalctl -u k3s -f` |
| **ls -l** | List files with details (permissions, owner) | `ls -l /usr/bin/kubectl` |
| **sudo** | Execute command as superuser | `sudo apt install package` |
| **id** | Show user and group IDs | `id` (shows uid, gid, groups) |
| **$USER** | Environment variable with current username | `echo $USER` → `thakur` |
| **|** (pipe) | Pass output of one command to another | `kubectl get pods \| grep nvidia` |
| **\|\|** | OR operator - run second command if first fails | `command1 \|\| echo "failed"` |
| **&&** | AND operator - run second command if first succeeds | `command1 && command2` |

### curl Flags Explained

| Flag | Meaning | Purpose |
|------|---------|---------|
| **-s** | Silent | Suppress progress meter |
| **-f** | Fail | Exit on HTTP errors |
| **-L** | Location | Follow redirects |

### chown vs chmod

| Command | What It Does | Format |
|--------|-------------|--------|
| **chown** | Changes **ownership** (who owns it) | `chown user:group file` |
| **chmod** | Changes **permissions** (what can be done) | `chmod 777 file` |

**Remember:** 
- `chown thakur:thakur` = user `thakur`, group `thakur` (your personal group)
- `chmod 777` = read/write/execute for owner, group, and others
- `chmod 600` = read/write for owner only (common for kubeconfig)

---

## Key Concepts & Mental Models

### Layered Architecture (GPU Setup)

```
┌─────────────────────────────────────────┐
│  AI Workloads (Pods: PyTorch, Jupyter)  │
├─────────────────────────────────────────┤
│  Kubernetes (k3s) + Device Plugin       │
├─────────────────────────────────────────┤
│  containerd with NVIDIA runtime         │
├─────────────────────────────────────────┤
│  NVIDIA Driver + Libraries (nvidia-smi) │
├─────────────────────────────────────────┤
│  Ubuntu (Host OS)                       │
└─────────────────────────────────────────┘
```

**Key Point:** Each layer must be configured correctly for GPU access to work.

### k3s vs k3d

| Aspect | Native k3s | k3d |
|--------|------------|-----|
| **Installation** | Direct on host OS | Inside Docker containers |
| **GPU Support** | ✅ Simple & Direct | ⚠️ More complex (extra layer) |
| **Use Case** | Production, GPU workloads | Testing, multi-node learning |
| **Resource Usage** | Lower overhead | Higher (Docker overhead) |

### Container Runtime Hierarchy

1. **Host OS** (Ubuntu)
2. **NVIDIA Driver** (nvidia-smi works here)
3. **Container Runtime** (containerd, Docker, nvidia-container-runtime)
4. **Kubernetes** (k3s)
5. **Pods** (your applications)

**Key Point:** `nvidia-container-runtime` must be in PATH for k3s to auto-detect it.

### GPU Resource Flow

1. **Host:** GPU hardware + NVIDIA driver
2. **Runtime:** `nvidia-container-runtime` enables GPU in containers
3. **Kubernetes:** Device Plugin advertises GPU to scheduler
4. **Pod:** Requests GPU via `resources.limits.nvidia.com/gpu: 1`
5. **Container:** Uses GPU via CUDA libraries

---

## Important Points to Remember

### 🎯 Critical Configuration Points

1. **`runtimeClassName: nvidia` is REQUIRED** for GPU pods in k3s (unless you change default runtime)
2. **`nvidia-container-runtime` must be in PATH** for k3s to auto-detect it
3. **Device Plugin needs `runtimeClassName: nvidia`** in its own pod spec
4. **k3s auto-detects runtimes on startup** - restart k3s after installing NVIDIA runtime
5. **kubeconfig location:** `~/.kube/config` (copy from `/etc/rancher/k3s/k3s.yaml`)

### 🔧 Common Patterns

**Installation Pattern:**
```bash
# 1. Install as root
sudo command

# 2. Change ownership to user
sudo chown $USER:$USER file

# 3. Set permissions
chmod 600 file
```

**Verification Pattern:**
```bash
# 1. Check on host
nvidia-smi

# 2. Check in Kubernetes
kubectl describe nodes | grep nvidia.com/gpu

# 3. Test in pod
kubectl logs gpu-test
```

### ⚠️ Common Gotchas

1. **k3s auto-detects runtimes** - no manual containerd config needed
2. **Device Plugin must use `runtimeClassName: nvidia`** - don't mount NVIDIA libs directly
3. **`k3s-arg` requires node filters** when multiple nodes exist (`@server:*`, `@agent:*`)
4. **k3d doesn't support `--servers-cpu` flag** - use `docker update --cpus` after creation
5. **kubeconfig permissions** - must be `600` (read/write for owner only)

### 📝 File Locations to Remember

| File | Location | Purpose |
|------|----------|---------|
| **k3s kubeconfig** | `/etc/rancher/k3s/k3s.yaml` | Original k3s config |
| **User kubeconfig** | `~/.kube/config` | Your kubectl config |
| **k3s containerd config** | `/var/lib/rancher/k3s/agent/etc/containerd/config.toml` | Check for NVIDIA runtime |
| **k3s node token** | `/var/lib/rancher/k3s/server/node-token` | Token for adding worker nodes |

### 🚀 Quick Reference Commands

**k3s:**
```bash
# Install
curl -sfL https://get.k3s.io | sudo sh -

# Check status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -f

# Uninstall
sudo /usr/local/bin/k3s-uninstall.sh
```

**GPU Verification:**
```bash
# Host check
nvidia-smi

# Kubernetes check
kubectl describe nodes | grep nvidia.com/gpu

# Device plugin logs
kubectl logs -n kube-system -l name=nvidia-device-plugin-ds
```

**kubectl:**
```bash
# Get nodes
kubectl get nodes

# Get pods
kubectl get pods --all-namespaces

# Describe node
kubectl describe nodes

# Apply YAML
kubectl apply -f file.yaml

# View logs
kubectl logs pod-name
```

---

## Learning Path Summary

### What You've Learned

1. ✅ **k3s vs k3d** - When to use each
2. ✅ **Native k3s setup** - Direct installation on Ubuntu
3. ✅ **GPU configuration** - NVIDIA Container Runtime + Device Plugin
4. ✅ **Container runtimes** - containerd, nvidia-container-runtime
5. ✅ **Kubernetes resources** - Pods, DaemonSets, runtimeClassName
6. ✅ **Linux basics** - chown, chmod, curl flags, systemd

### Next Steps for AI Workloads

1. **PyTorch Pods** - Deploy GPU-accelerated training jobs
2. **Jupyter Notebooks** - Interactive GPU development
3. **Model Serving** - Deploy trained models as services
4. **Multi-GPU** - Scale across multiple GPUs
5. **Resource Management** - Requests, limits, node selectors

---

## Quick Mental Models

### "What is X?" Quick Answers

- **k3s** = Lightweight Kubernetes (single binary, easy install)
- **k3d** = k3s running in Docker containers (for testing)
- **containerd** = Container runtime (what actually runs containers)
- **nvidia-container-runtime** = Wrapper that adds GPU support to containers
- **Device Plugin** = Tells Kubernetes "I have GPUs available"
- **runtimeClassName** = "Use this runtime for this pod" (nvidia for GPU pods)
- **DaemonSet** = "Run this pod on every node"
- **kubeconfig** = "Here's how to connect to my cluster"
- **CUDA** = Programming platform to use GPU for computation
- **nvidia-smi** = "Show me GPU status" (like `top` for GPUs)

---

**Last Updated:** Based on your k3s + GPU learning journey  
**Purpose:** Quick reference for terminology and concepts  
**Use Case:** Bookmark this for quick lookups while learning!
