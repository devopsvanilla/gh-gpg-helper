#!/bin/bash

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to list GPG keys
list_gpg_keys() {
    echo "Available GPG keys:"
    gpg --list-secret-keys --keyid-format LONG
}

# Function to select existing key
select_existing_key() {
    local keys=()
    local emails=()
    while IFS= read -r line; do
        keys+=("$(echo "$line" | awk '{print $2}' | awk -F'/' '{print $2}')")
    done < <(gpg --list-secret-keys --keyid-format LONG | grep sec)
    while IFS= read -r line; do
        emails+=("$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ //')")
    done < <(gpg --list-secret-keys | grep uid)

    if [ ${#keys[@]} -eq 0 ]; then
        echo "No existing keys found."
        return 1
    fi

    echo "Available keys:"
    for i in "${!keys[@]}"; do
        echo "$((i+1))) ${keys[$i]} - ${emails[$i]}"
    done

    read -rp "Select key number (1-${#keys[@]}): " key_num

    if [[ "$key_num" =~ ^[0-9]+$ ]] && [ "$key_num" -ge 1 ] && [ "$key_num" -le "${#keys[@]}" ]; then
        KEY_ID="${keys[$((key_num-1))]}"
        return 0
    else
        echo "Invalid selection"
        return 1
    fi
}

# Function to install GitHub CLI based on OS
install_gh_cli() {
    if command_exists apt; then
        echo "Installing GitHub CLI using apt..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install gh -y
    elif command_exists dnf; then
        echo "Installing GitHub CLI using dnf..."
        sudo dnf install gh -y
    elif command_exists yum; then
        echo "Installing GitHub CLI using yum..."
        sudo yum install gh -y
    elif command_exists brew; then
        echo "Installing GitHub CLI using Homebrew..."
        brew install gh
    else
        echo "Could not determine package manager. Please install GitHub CLI manually."
        exit 1
    fi
}

# Function to create new GPG key
create_new_key() {
    echo "Please enter the information for your new GPG key:"
    read -rp "Name (must match GitHub username): " NAME
    read -rp "Email (must match GitHub email): " EMAIL
    read -rp "Comment (optional - press enter to skip): " COMMENT

    cat >gpg_key_config <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Name-Real: $NAME
Name-Email: $EMAIL
Name-Comment: $COMMENT
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

    echo "Generating GPG key..."
    gpg --batch --generate-key gpg_key_config
    rm gpg_key_config

    KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | tail -n 1 | awk '{print $2}' | awk -F'/' '{print $2}')

    if [ -z "$KEY_ID" ]; then
        echo "Failed to get GPG key ID"
        exit 1
    fi
}

# Check for GPG installation
if ! command_exists gpg; then
    echo "GPG is not installed. Please install it first."
    exit 1
fi

# Check for existing GPG keys
if gpg --list-secret-keys --keyid-format LONG | grep sec >/dev/null 2>&1; then
    echo "Existing GPG keys found."
    list_gpg_keys

    echo -e "\nWhat would you like to do?"
    echo "1) Use an existing key"
    echo "2) Create a new key"
    read -rp "Enter choice (1 or 2): " key_choice

    case $key_choice in
        1)
            if ! select_existing_key; then
                echo "Failed to select existing key. Creating new key instead."
                create_new_key
            fi
            ;;
        2)
            create_new_key
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    echo "No existing GPG keys found. Creating new key..."
    create_new_key
fi

# Check for GitHub CLI and install if missing
if ! command_exists gh; then
    echo "GitHub CLI (gh) is not installed."
    read -p "Would you like to install it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_gh_cli
    else
        echo "GitHub CLI is required for this script. Exiting."
        exit 1
    fi
fi

# Check GitHub CLI authentication
if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated."
    echo "Starting GitHub authentication process..."

    echo "Select authentication method:"
    echo "1) Browser (Recommended)"
    echo "2) Token"
    read -rp "Enter choice (1 or 2): " auth_choice

    case $auth_choice in
        1)
            gh auth login -w
            ;;
        2)
            echo "Please create a Personal Access Token with 'admin:gpg_key' scope at:"
            echo "https://github.com/settings/tokens/new"
            gh auth login -p ssh
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    if ! gh auth status >/dev/null 2>&1; then
        echo "Authentication failed. Please try again."
        exit 1
    fi
fi

# Export and add GPG key to GitHub
GPG_PUBLIC_KEY=$(gpg --armor --export "$KEY_ID")

if [ -z "$GPG_PUBLIC_KEY" ]; then
    echo "Failed to export GPG public key"
    exit 1
fi

echo "Adding GPG key to GitHub..."
echo "$GPG_PUBLIC_KEY" | gh gpg-key add -

# Configure git
git config --global user.signingkey "$KEY_ID"
git config --global commit.gpgsign true

echo -e "\n=== Configuration Complete ==="
echo "Your GPG key ID is: $KEY_ID"
echo "The key has been automatically added to your GitHub account"

# Backup option
echo -e "\nWould you like to backup your GPG key? (y/n)"
read -r BACKUP
if [[ $BACKUP =~ ^[Yy]$ ]]; then
    BACKUP_DIR="$HOME/gpg_backup_$(date +%Y%m%d)"
    mkdir -p "$BACKUP_DIR"
    gpg --armor --export "$KEY_ID" > "$BACKUP_DIR/public_key.asc"
    gpg --armor --export-secret-keys "$KEY_ID" > "$BACKUP_DIR/private_key.asc"
    echo "Keys backed up to: $BACKUP_DIR"
    echo "IMPORTANT: Store these files securely!"
fi

# Configure GPG agent
if [ -d "$HOME/.gnupg" ]; then
    if [ ! -f "$HOME/.gnupg/gpg-agent.conf" ]; then
        echo "default-cache-ttl 3600" > "$HOME/.gnupg/gpg-agent.conf"
        echo "max-cache-ttl 7200" >> "$HOME/.gnupg/gpg-agent.conf"
        gpg-connect-agent reloadagent /bye
    fi
fi

# Test signing
echo -e "\nWould you like to test the GPG signing with a test repository? (y/n)"
read -r TEST_SIGNING
if [[ $TEST_SIGNING =~ ^[Yy]$ ]]; then
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || exit
    git init
    echo "# Test Repository" > README.md
    git add README.md


    if git commit -S -m "Test signed commit"; then
        echo "GPG signing test successful!"
    else
        echo "GPG signing test failed. Please check your configuration."
    fi

    cd - > /dev/null || exit
    rm -rf "$TEST_DIR"
fi

echo -e "\nSetup complete! You can now make signed commits."
echo "To verify signed commits, use: git log --show-signature"
