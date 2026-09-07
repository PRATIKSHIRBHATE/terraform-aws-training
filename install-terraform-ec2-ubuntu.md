# Install Terraform on an Ubuntu EC2 Instance

This guide walks through installing Terraform on an Ubuntu EC2 instance using HashiCorp's official APT repository (the recommended method, since it keeps Terraform updated through `apt`).

## Prerequisites

- An Ubuntu EC2 instance (22.04, 24.04, or newer)
- SSH access to the instance
- `sudo` or root privileges
- Internet access from the instance (an outbound route via Internet Gateway or NAT)

---

## Step 1: Connect to the EC2 Instance

From your local machine, SSH in using your key pair:

```bash
ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

---

## Step 2: Switch to the Root User

You can run the install with `sudo` on each command, or switch to the root user first. Any of these work:

```bash
# Switch to root using sudo (most common on EC2 Ubuntu)
sudo -i

# Or, switch to root with a login shell
sudo su -

# Or, switch to root without a login shell (keeps current environment)
sudo su
```

To confirm you are now root:

```bash
whoami        # should print: root
```

To leave the root shell and return to the `ubuntu` user:

```bash
exit
```

> Note: The commands below are written with `sudo`. If you already switched to root, you can drop the `sudo` prefix.

---

## Step 3: Update the System and Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common curl
```

---

## Step 4: Add the HashiCorp GPG Key

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

Verify the key fingerprint (optional but recommended):

```bash
gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint
```

---

## Step 5: Add the HashiCorp APT Repository

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
```

---

## Step 6: Install Terraform

```bash
sudo apt-get update
sudo apt-get install -y terraform
```

---

## Step 7: Verify the Installation

```bash
terraform version
```

You should see output similar to:

```
Terraform v1.x.x
on linux_amd64
```

You can also confirm the CLI works:

```bash
terraform -help
```

---

## Updating Terraform Later

Because Terraform is installed from the APT repository, you can update it with:

```bash
sudo apt-get update
sudo apt-get upgrade -y terraform
```

---

## Alternative: Manual Binary Install (No APT)

If you prefer a specific version or cannot use the repository:

```bash
# Set the version you want
TF_VERSION="1.9.5"

# Download and install
cd /tmp
curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
sudo apt-get install -y unzip
unzip "terraform_${TF_VERSION}_linux_amd64.zip"
sudo mv terraform /usr/local/bin/
terraform version
```

> For ARM-based instances (e.g., Graviton / `t4g`), replace `linux_amd64` with `linux_arm64`.

---

## Quick Reference: Switch User to Root

```bash
sudo -i        # root login shell
sudo su -      # root login shell (alternative)
sudo su        # root shell, keeps current environment
whoami         # verify current user
exit           # return to the previous user
```
