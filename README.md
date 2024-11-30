# gh-gpg-helper
![Security and Best Practices Scan](https://github.com/devopsvanilla/gh-gpg-helper/workflows/Security%20and%20Best%20Practices%20Scan/badge.svg)


A bash script to automate the setup of GPG keys for GitHub commit signing. This script helps you create, configure, and add GPG keys to your GitHub account with minimal manual intervention.

## Features

- Automatic GPG key generation
- GitHub CLI installation check and automated installation
- Automatic configuration of git for commit signing
- Automatic addition of GPG key to GitHub account
- Optional GPG key backup
- Cross-platform support (Linux and macOS)

## Requirements

- Bash shell
- Internet connection
- One of the following package managers:
  - apt (Debian/Ubuntu)
  - dnf (Fedora)
  - yum (RHEL/CentOS)
  - brew (macOS)
- GitHub account
- Sudo privileges (for installing dependencies)

## How to use

```bash
# First, download the script
curl -O https://raw.githubusercontent.com/devopsvanilla/gh-gpg-helper/refs/heads/main/gh-gpg.sh

# Then run it
bash gh-gpg.sh
```

⚠️ Security Notice : Always review scripts before executing them directly from the internet.

## What the Script Does
1. Checks for and installs required dependencies (GPG and GitHub CLI)

2. Offers options to:

- Create a new GPG key

- Use an existing GPG key

3. Configures git for commit signing

4. Adds the GPG key to your GitHub account

5. Offers to create a backup of your GPG keys

6. Sets up everything for signed commits

## After Installation

To verify the setup, you can:
```bash
Check your GPG keys: gpg --list-secret-keys --keyid-format LONG
```

Verify git configuration:
```bash
git config --global --list | grep -i gpg
```

## How to sign commits

#### To sign a specific commit
```bash
git commit -S -m "your commit message"
```

#### To sign all commits automatically (global setting)
```bash
git config --global commit.gpgsign true
```

#### To sign all commits automatically (repository-specific setting)
```bash
git config commit.gpgsign true
```

#### To verify a signed commit
```bash
git verify-commit <commit-hash>
```

#### To show signatures in git log
```bash
git log --show-signature
```

## Troubleshooting
If you encounter authentication issues:

1. Ensure you're logged in to GitHub CLI: gh auth login

2. Verify your GPG key is correctly added: gh gpg-key list

3. Confirm your git configuration: git config --global --list

## License
MIT License

Copyright (c) 2024 Sandro Cicero (aka DevOpsVanilla.guru)