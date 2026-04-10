#!/usr/bin/env bash
set -e

echo "======================================"
echo "🚀 STAGE9 ENVIRONMENT RESTORE"
echo "======================================"

# --------------------------------------
# 1. SYSTEM SETUP
# --------------------------------------
echo "📦 Installing system dependencies..."
sudo apt update
sudo apt install -y python3.10 python3.10-venv python3.10-dev cmake build-essential git

# --------------------------------------
# 2. PYTHON ENV (F´ LOCKED VERSIONS)
# --------------------------------------
echo "🐍 Creating Python venv..."
rm -rf ~/fprime310-venv
python3.10 -m venv ~/fprime310-venv
source ~/fprime310-venv/bin/activate

pip install --upgrade pip

echo "📦 Installing F´ toolchain..."
pip install fprime-tools==3.1.0
pip install fprime-gds==3.1.1
pip install fprime-fpp==1.0.2

# Fix legacy deps (CRITICAL)
pip install \
  jinja2==2.11.3 \
  markupsafe==2.0.1 \
  click==7.1.2 \
  cookiecutter==1.7.3 \
  flask==1.1.4 \
  --force-reinstall

pip check

# --------------------------------------
# 3. CLONE PROJECT
# --------------------------------------
echo "📥 Cloning project..."
cd ~
rm -rf Stage9MotorBridge
git clone https://github.com/chumnap2/Stage9MotorBridge.git
cd Stage9MotorBridge

# --------------------------------------
# 4. CONFIGURE F´ PATH
# --------------------------------------
echo "🧩 Writing settings.ini..."
cat > settings.ini << EOF
[fprime]
framework_path=$HOME/fprime-motorbridge/fprime-3.1.0

[deployment]
platform=Linux
topology=Stage9MotorBridgeTopology
EOF

# --------------------------------------
# 5. BUILD (CLEAN)
# --------------------------------------
echo "🧹 Cleaning build..."
rm -rf build build-fprime-automatic-*

echo "⚙️ Generating..."
fprime-util generate

echo "🔨 Building..."
fprime-util build

echo "======================================"
echo "✅ ENV RESTORE COMPLETE"
echo "======================================"
