# LinkedIn Post Content

## Post Text (~150 words)

---

**Running LLMs on Kubernetes with GPU acceleration**

Built a self-hosted AI stack this week: k3s + Ollama + Open-webui, all running on my local GPU.

Why this matters:
- Full control over your AI infrastructure
- No cloud costs or API limits  
- Real GPU workloads on Kubernetes

The key challenge? Getting GPU passthrough working correctly. k3s auto-detects `nvidia-container-runtime` but you need `runtimeClassName: nvidia` in every GPU pod spec - including the NVIDIA device plugin itself.

Stack:
- k3s (lightweight Kubernetes)
- Ollama (LLM inference server)
- Open-webui (ChatGPT-like interface)
- NVIDIA GPU with container runtime

Everything runs with proper health checks, persistent storage, and clean manifests.

Next up: GPU time-slicing for multi-tenant workloads.

Code: [GitHub link]

#kubernetes #AI #GPU #DevOps #MLOps #LLM #SelfHosted

---

## Screenshots to Capture

### 1. Hero Shot - Open-webui Chat
- Open-webui with a model conversation
- Shows it actually works
- Crop to show clean UI

### 2. GPU Proof - nvidia-smi
```bash
# Run this and screenshot
nvidia-smi
# Should show ollama process using GPU
```

### 3. Kubernetes View - Pods Running
```bash
# Run this and screenshot
kubectl get pods -n ollama -o wide
# Shows both pods running with node info
```

### 4. Architecture Diagram
Create in Excalidraw or draw.io:
```
Browser
   ↓
Open-webui (8080)
   ↓
Ollama (11434)
   ↓
NVIDIA GPU
```

---

## Hashtags Strategy

**Primary (always include):**
- #kubernetes
- #AI
- #GPU

**Secondary (pick 2-3):**
- #DevOps
- #MLOps
- #LLM
- #SelfHosted
- #k3s
- #NVIDIA
- #OpenSource

---

## Posting Tips

1. **Best times**: Tuesday-Thursday, 8-10 AM or 12-1 PM (your timezone)
2. **Image**: Hero shot (Open-webui) as main image
3. **First comment**: Add architecture diagram + "Full code on GitHub"
4. **Engage**: Reply to comments within first hour

---

## Alternative Hooks (choose one)

1. "Running LLMs on Kubernetes with GPU acceleration"
2. "Self-hosted ChatGPT on my local GPU"
3. "Built my own AI infrastructure this week"
4. "No cloud. No API limits. Just local GPU power."
