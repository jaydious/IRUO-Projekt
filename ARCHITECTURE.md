# CloudLearn Architecture Documentation

## System Architecture

### User Structure
- **Instructor**: Full administrative access with 4 VMs
- **Students**: Isolated environments with basic VMs

### Virtual Machine Layout per User
- `{username}-jump-vm` - Bastion host with public access
- `{username}-wordpress-vm` - Web application server
- `{username}-storage-vm` - Additional storage server  
- `{username}-db-vm` - Database server

### Network Architecture
- Each user gets isolated `/24` private network
- Networks: `192.168.10.0/24`, `192.168.20.0/24`, `192.168.30.0/24`
- Routers connect private networks to external provider
- Only jump hosts have floating IPs

### Security Model
- **Student Security Groups**: SSH (22), HTTP (80), HTTPS (443)
- **Instructor Security Groups**: Full internal network access
- Network isolation prevents cross-user communication
- Least-privilege principle applied throughout

### Storage Architecture
- Each VM has system disk + 10GB additional disk
- Disks are attached but not automatically mounted
- Ready for application-specific storage configuration

## Resource Tagging
All resources are tagged with:
- `course=test` - Primary project identifier
- `user={username}` - Resource owner
- `role={role}` - User role (student/instructor)

## Deployment Automation
- Idempotent scripts safe for multiple runs
- CSV-driven user management
- Comprehensive cleanup and status monitoring