# 🩺 Self-Healing AWS EC2 System using Prometheus, Alertmanager & AWS Lambda

This project implements an **automated EC2 self-healing system** where high CPU usage or instance failures automatically trigger **AWS Lambda** to **reboot** the affected instance.  
It uses **Prometheus** for monitoring, **Alertmanager** for alerting, and **Terraform** for provisioning the Lambda and API Gateway infrastructure.

---

## 🚀 Architecture Overview

**Components involved:**
1. **Prometheus (Monitor EC2 Instance)**
   - Collects metrics using **Node Exporter**.
   - Defines alerting rules (e.g., High CPU, Instance Down).
   - Sends alerts to Alertmanager.

2. **Alertmanager**
   - Handles alerts from Prometheus.
   - Routes alerts to AWS Lambda via **API Gateway Webhook**.
   - Can be extended to notify Slack, Email, etc.

3. **AWS API Gateway**
   - Acts as an HTTPS endpoint (webhook) to receive alerts from Alertmanager.
   - Invokes AWS Lambda when a POST request is received.

4. **AWS Lambda**
   - Parses the alert payload.
   - Identifies the EC2 instance from its private IP.
   - Reboots the instance using the **Boto3 EC2 client**.

5. **Terraform**
   - Automates deployment of API Gateway, Lambda, and IAM roles/policies.

---

## 🧩 Project Flow

**Prometheus (Monitor EC2)** <br>
               ↓<br>
**Alert triggered (e.g., CPU > 85%)** <br>
              ↓<br>
**Alertmanager → POST /alert → API Gateway** <br>
               ↓<br>
**API Gateway → invokes Lambda**<br>
               ↓<br>
**Lambda → identifies EC2 → reboots instance** <br>
               ↓<br>
**EC2 rebooted automatically ✅**<br>