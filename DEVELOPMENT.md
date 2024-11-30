## Git Hooks Setup

### Setup Script

The `setup-hooks.sh` script helps automate the installation and configuration of Git hooks for this project. These hooks help maintain code quality and consistency.

### Prerequisites

Before running the setup script, ensure you have:
- Bash shell
- Git installed
- Appropriate permissions to execute scripts

### Installation

1. Make the script executable:
```bash
   chmod +x setup-hooks.sh
```

2. Run the setup script:
```bash
 ./setup-hooks.sh
```

## What the Script Does

The script performs the following tasks:

*1.* Creates necessary hooks directory if it doesn't exist

*2.* Installs pre-commit hooks for:

* Code formatting validation

* Linting checks

* GPG signature verification

*3.* Sets appropriate permissions for the hooks

*4.* Validates the hook installation

## Verifying Installation

To verify the hooks are properly installed:

*1.* Check the .git/hooks directory:
```bash
ls -la .git/hooks
```

*2.* Try making a commit to test the pre-commit hook:
```bash
git commit -m "test commit"
```

## Troubleshooting

If you encounter any issues:

*1.* Ensure the script has executable permissions

*3.* Check the hooks directory exists: .git/hooks

*4.* Verify script output for any error messages

*5.* Ensure Git is properly configured with your GPG key

## Manual Override

To temporarily bypass the hooks (not recommended):
```bash
git commit --no-verify -m "your message"
```

## Additional Notes

* The hooks are local to your repository

* New contributors should run the setup script after cloning

* Updates to the hooks require re-running the setup script
