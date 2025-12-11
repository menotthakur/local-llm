#!/bin/bash
# =============================================================================
# Native k3s Installation with GPU Support
# =============================================================================
# This script installs k3s directly on Ubuntu with NVIDIA GPU support.
# Run with: sudo ./install.sh
#
# Options:
#   --no-gpu      Skip GPU setup (install k3s only)
#   --help        Show this help message
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
K3S_VERSION="latest"
ENABLE_GPU=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-gpu)
            ENABLE_GPU=false
            shift
            ;;
        --help)
            echo "Usage: sudo ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-gpu    Skip GPU setup (install k3s only)"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Native k3s Installation with GPU Support${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# -----------------------------------------------------------------------------
# 1. Prerequisites
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[1/6] Installing prerequisites...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget > /dev/null
echo -e "${GREEN}✓ Prerequisites installed${NC}"

# -----------------------------------------------------------------------------
# 2. GPU Detection
# -----------------------------------------------------------------------------
DETECTED_GPU="none"

if [[ "$ENABLE_GPU" == "true" ]]; then
    echo -e "${YELLOW}[2/6] Detecting GPU...${NC}"
    
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        DETECTED_GPU="nvidia"
        echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
        nvidia-smi --query-gpu=name --format=csv,noheader | head -1
    elif lspci | grep -i "vga\|3d\|display" | grep -i amd &> /dev/null; then
        DETECTED_GPU="amd"
        echo -e "${YELLOW}⚠ AMD GPU detected (manual configuration may be needed)${NC}"
    else
        echo -e "${YELLOW}⚠ No GPU detected${NC}"
    fi
else
    echo -e "${YELLOW}[2/6] Skipping GPU detection (--no-gpu flag)${NC}"
fi

# -----------------------------------------------------------------------------
# 3. NVIDIA Container Runtime (if NVIDIA GPU detected)
# -----------------------------------------------------------------------------
if [[ "$DETECTED_GPU" == "nvidia" ]]; then
    echo -e "${YELLOW}[3/6] Setting up NVIDIA Container Runtime...${NC}"
    
    if ! command -v nvidia-container-runtime &> /dev/null; then
        echo "  Installing nvidia-container-runtime..."
        
        # Add NVIDIA GPG key
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
            | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null
        
        # Add repository
        echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/amd64 /" \
            > /etc/apt/sources.list.d/nvidia-container-toolkit.list
        
        # Install
        apt-get update -qq
        apt-get install -y -qq nvidia-container-runtime > /dev/null
        
        echo -e "${GREEN}✓ nvidia-container-runtime installed${NC}"
    else
        echo -e "${GREEN}✓ nvidia-container-runtime already installed${NC}"
    fi
    
    # Verify it's in PATH
    which nvidia-container-runtime > /dev/null
else
    echo -e "${YELLOW}[3/6] Skipping NVIDIA runtime (no NVIDIA GPU)${NC}"
fi

# -----------------------------------------------------------------------------
# 4. Install k3s
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[4/6] Installing k3s...${NC}"

if ! command -v k3s &> /dev/null; then
    if [[ "$K3S_VERSION" == "latest" ]]; then
        curl -sfL https://get.k3s.io | sh -
    else
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -
    fi
    
    # Wait for k3s to be ready
    echo "  Waiting for k3s to start..."
    sleep 5
    while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
        sleep 2
    done
    
    echo -e "${GREEN}✓ k3s installed${NC}"
else
    echo -e "${GREEN}✓ k3s already installed${NC}"
fi

# Verify k3s is running
systemctl is-active --quiet k3s || systemctl start k3s

# Restart k3s if NVIDIA runtime was just installed (for auto-detection)
if [[ "$DETECTED_GPU" == "nvidia" ]]; then
    echo "  Restarting k3s to detect NVIDIA runtime..."
    systemctl restart k3s
    sleep 5
fi

k3s --version

# -----------------------------------------------------------------------------
# 5. Setup kubectl and kubeconfig
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[5/6] Setting up kubectl...${NC}"

# Create .kube directory for actual user
mkdir -p "$ACTUAL_HOME/.kube"

# Copy kubeconfig
cp /etc/rancher/k3s/k3s.yaml "$ACTUAL_HOME/.kube/config"
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.kube/config"
chmod 600 "$ACTUAL_HOME/.kube/config"

# Replace 127.0.0.1 with localhost
sed -i 's/127\.0\.0\.1/localhost/g' "$ACTUAL_HOME/.kube/config"

echo -e "${GREEN}✓ kubeconfig set up at $ACTUAL_HOME/.kube/config${NC}"

# Test kubectl
export KUBECONFIG="$ACTUAL_HOME/.kube/config"
kubectl get nodes > /dev/null
echo -e "${GREEN}✓ kubectl working${NC}"

# -----------------------------------------------------------------------------
# 6. Install NVIDIA Device Plugin (if NVIDIA GPU detected)
# -----------------------------------------------------------------------------
if [[ "$DETECTED_GPU" == "nvidia" ]]; then
    echo -e "${YELLOW}[6/6] Installing NVIDIA Device Plugin...${NC}"
    
    # Check if already installed
    if ! kubectl get daemonset -n kube-system nvidia-device-plugin-daemonset &> /dev/null; then
        kubectl apply -f - <<'EOF'
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
        echo -e "${GREEN}✓ NVIDIA Device Plugin installed${NC}"
    else
        echo -e "${GREEN}✓ NVIDIA Device Plugin already installed${NC}"
    fi
    
    # Wait for device plugin to be ready
    echo "  Waiting for device plugin..."
    sleep 15
    
    # Check GPU resources
    echo ""
    echo -e "${BLUE}GPU Resources:${NC}"
    kubectl describe nodes | grep -A 2 "nvidia.com/gpu" || echo "  GPU resources not yet available (may take a minute)"
else
    echo -e "${YELLOW}[6/6] Skipping NVIDIA Device Plugin (no NVIDIA GPU)${NC}"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "  ${BLUE}Node Type:${NC} Single node (control plane + worker)"
echo -e "  ${BLUE}GPU Support:${NC} $DETECTED_GPU"
echo -e "  ${BLUE}kubeconfig:${NC} $ACTUAL_HOME/.kube/config"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
if [[ "$DETECTED_GPU" == "nvidia" ]]; then
    echo "  kubectl describe nodes | grep -i gpu"
fi
echo ""
echo -e "${YELLOW}To uninstall:${NC}"
echo "  /usr/local/bin/k3s-uninstall.sh"
echo ""
