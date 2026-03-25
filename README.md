# DevOps Assignment - LDC

**Student:** Pratham Darji 
**Institute:** K J Somaiya Institute of Technology  
**Cloud Provider:** Amazon Web Services (AWS) - ap-south-1 (Mumbai)  
**Live Application:** http://3.110.88.30:5000/

---

## Project Overview

This project demonstrates a complete DevSecOps workflow where infrastructure is provisioned on AWS using Terraform, a Python web application is containerized using Docker, and a Jenkins CI/CD pipeline automatically scans the infrastructure code for security vulnerabilities before deployment.

The goal was to ensure that infrastructure deployed to the cloud is secure by default. The pipeline intentionally includes a security vulnerability which is detected by Trivy, analyzed, and then fixed before the infrastructure is provisioned.

---

## Tools and Technologies

| Category | Tool | Details |
|----------|------|---------|
| Language | Python 3.11 | Flask web framework |
| Containerization | Docker | Dockerfile + docker-compose |
| Infrastructure as Code | Terraform | v1.14.7 |
| CI/CD | Jenkins | Running via Docker (LTS JDK17) |
| Security Scanner | Trivy | Misconfiguration scanning |
| Cloud | AWS EC2 | t3.micro, ap-south-1 |
| Version Control | Git + GitHub | Source code management |

---

## Web Application and Docker

A simple Python Flask web application was built and containerized. The application runs on port 5000 and includes a health check endpoint at /health.

To run locally:
```
docker-compose up --build
```

## Infrastructure as Code (Terraform)

Terraform was used to provision the following AWS resources:

- VPC with DNS support enabled
- Public subnet with internet gateway
- Route table for public access
- Security group with ingress rules for ports 80 and 5000
- EC2 instance (t3.micro, Ubuntu 22.04) with Docker pre-installed via user data
- Key pair for SSH access

The Terraform code is in the terraform/ directory.

---

## Jenkins Pipeline

Jenkins was run locally using Docker and a three-stage pipeline was configured.

**Stage 1 - Checkout**  
Pulls the latest source code from the GitHub repository.

**Stage 2 - Infrastructure Security Scan**  
Runs Trivy against the Terraform files to detect misconfigurations and vulnerabilities. The pipeline fails if any CRITICAL issues are found, preventing insecure infrastructure from being deployed.

**Stage 3 - Terraform Plan**  
Runs terraform init and terraform plan to validate the infrastructure configuration. AWS credentials are passed securely via Jenkins credentials store.

---

## Security Vulnerability and Remediation

**Intentional Vulnerability Introduced**

The initial Terraform code contained an overly permissive egress rule in the security group that allowed all outbound traffic to any IP address on any port.

```hcl
# Vulnerable code
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

**Trivy Detection**

Trivy detected this as a CRITICAL misconfiguration:

```
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
main.tf:115 via main.tf:111-116 (egress) via main.tf:78-122 (aws_security_group.web)
```

**Fixed Code**

The egress rule was updated to only allow outbound traffic on ports 80 and 443, following the principle of least privilege.

```hcl
# Fixed code
egress {
  description = "Allow HTTP outbound only"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

egress {
  description = "Allow HTTPS outbound only"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

After applying the fix, the pipeline was re-run and Trivy reported zero critical issues.

---

## Before and After Security Report

**Before Fix**
- Trivy result: FAILURES: 1 (CRITICAL: 1)
- Issue: AWS-0104 - unrestricted egress to 0.0.0.0/0
- Pipeline result: FAILED

**After Fix**
- Trivy result: FAILURES: 0
- Pipeline result: SUCCESS
- All three stages passed

Screenshots are in the screenshots/ directory.

---

## AI Usage Log

**Tool Used:** Claude (Anthropic)

**Prompt Used:**

"I got this Trivy error on my Terraform code - AWS-0104 CRITICAL, security group allows unrestricted egress, cidr_blocks = 0.0.0.0/0 on line 115 of main.tf. What does this mean and how do I fix i"

**Summary of Identified Risks**

The vulnerability allowed the EC2 instance to make outbound connections to any IP address on any port. This is a security risk because if the server were compromised, an attacker could use it to exfiltrate data to any external server, download malicious tools, or use the instance to attack other systems without restriction.

**How AI Recommendations Improved Security**

The AI explained that the fix was to replace the open-ended egress rule with specific rules that only allow outbound traffic on port 80 (HTTP) and port 443 (HTTPS). This is the minimum required for the application to function - it needs to pull packages and communicate with external services over standard web ports. All other outbound traffic is now blocked by default, significantly reducing the attack surface of the deployed instance.``

---

## Submission Checklist

- Source code and Docker files - included
- Jenkinsfile - included
- terraform/ directory (final secured version) - included
- README.md with GenAI Usage Report - included
- Screenshots - included in screenshots/ directory
- Video recording - submitted separately
- Live application - http://13.127.174.60:5000/
