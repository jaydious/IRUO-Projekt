# Deployment Guide

## Prerequisites
- OpenStack CLI installed and configured
- Access to admin project
- RHEL 8 image available
- Default flavor available

## Quick Deployment
1. Clone repository
2. Update `config/users.csv` if needed
3. Run: `./scripts/deploy-cloudlearn.sh config/users.csv`
4. Check status: `./scripts/status-cloudlearn.sh`

## Customization
### Adding Users
Edit `config/users.csv`:
```csv
ime;prezime;rola
new;user;student