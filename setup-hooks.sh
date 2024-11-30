#!/bin/bash

echo "Starting setup of development hooks..."

# Create Python virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
    if [ $? -ne 0 ]; then
        echo "Failed to create virtual environment. Installing python3-venv..."
        sudo apt-get update
        sudo apt-get install -y python3-venv
        python3 -m venv .venv
    fi
fi

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate
if [ $? -ne 0 ]; then
    echo "Failed to activate virtual environment"
    exit 1
fi

# Check and install act
if ! command -v act &> /dev/null; then
    echo "Installing act..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install act
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
    else
        echo "Please install act manually from: https://github.com/nektos/act"
        exit 1
    fi
fi

# Install pre-commit in virtual environment
echo "Installing pre-commit..."
pip install pre-commit

# Install the pre-commit hooks
pre-commit install

# Create artifacts directory if it doesn't exist
mkdir -p /tmp/artifacts

# Verify installations
echo "Verifying installations..."
echo "act version: $(act --version)"
echo "pre-commit version: $(pre-commit --version)"
echo "Python version: $(python --version)"

# Ensure .gitignore has necessary entries
if [ ! -f ".gitignore" ]; then
    touch .gitignore
fi

# Add entries to .gitignore if they don't exist
ENTRIES=(
    ".venv/"
    "__pycache__/"
    "*.pyc"
    ".pre-commit-config.yaml.cache"
)

for entry in "${ENTRIES[@]}"; do
    if ! grep -q "^$entry$" .gitignore 2>/dev/null; then
        echo "$entry" >> .gitignore
    fi
done

echo "✅ Setup complete! Pre-commit hooks are now installed."
echo ""
echo "⚠️  Important: Before committing, always ensure the virtual environment is activated:"
echo "    source .venv/bin/activate"
echo ""
echo "💡 To deactivate the virtual environment when done, simply type:"
echo "    deactivate"
