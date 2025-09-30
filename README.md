# CloudLearn OpenStack Deployment

Automated OpenStack deployment for virtual learning environments with WordPress architecture.

## 📋 Project Overview
This project implements a complete OpenStack infrastructure for a web development course, featuring:
- Isolated environments for students and instructors
- Automated deployment via bash scripts
- WordPress-ready architecture
- Network security and resource tagging

## 🚀 Quick Start
```bash
git clone https://github.com/yourusername/cloudlearn-openstack
cd cloudlearn-openstack

# Deploy the environment
./scripts/deploy-cloudlearn.sh config/users.csv

# Check status
./scripts/status-cloudlearn.sh

# Cleanup when done
./scripts/cleanup-cloudlearn.sh