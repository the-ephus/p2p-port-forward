# Contributing to p2p-port-forward

Thank you for your interest in contributing! This project aims to provide a reliable NAT-PMP port forwarding solution for unRAID users.

## How to Contribute

### Reporting Issues
- Use GitHub Issues to report bugs or request features
- Include your unRAID version, container details, and log output
- Search existing issues before creating new ones

### Code Contributions

#### Prerequisites
- Basic knowledge of bash scripting
- Understanding of Docker, NAT-PMP, and VPN concepts
- Access to unRAID for testing (recommended)

#### Development Setup
1. Fork the repository
2. Clone your fork locally
3. Create a feature branch: `git checkout -b feature-name`
4. Make your changes
5. Test thoroughly (see Testing section)
6. Submit a pull request

#### Code Standards
- Follow existing code style and patterns
- Use shellcheck for linting: `shellcheck p2p-port-forward-script.sh`
- Add comments for complex logic
- Validate input parameters
- Use proper error handling with informative messages
- Test with different container types when possible

#### Testing
Since this script requires specific unRAID/Docker/VPN setup:
- Test syntax: `bash -n p2p-port-forward-script.sh`
- Test with shellcheck: `shellcheck p2p-port-forward-script.sh`
- For full testing, use a development unRAID instance
- Test edge cases: container not running, network issues, etc.

### Documentation
- Update README.md for user-facing changes
- Add examples for new configuration options
- Include troubleshooting steps for common issues

### Commit Guidelines
- Use clear, descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused on single changes

## Questions?
Open an issue for questions about contributing or project direction.