# Install the AWS CLI (v2) on an Ubuntu EC2 Instance

This guide installs the **AWS CLI v2** on an Ubuntu EC2 instance using the official AWS installer (the recommended method). AWS CLI v2 is a standalone binary with no Python dependency and is the only version that supports newer services and SSO.

> Avoid `apt install awscli` from Ubuntu's default repositories — it typically installs the older v1 and can be out of date.

## Prerequisites

- An Ubuntu EC2 instance (22.04, 24.04, or newer)
- SSH access to the instance
- `sudo` or root privileges
- Internet access from the instance (outbound via Internet Gateway or NAT)

---

## Step 1: Connect to the EC2 Instance

From your local machine:

```bash
ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

---

## Step 2: (Optional) Switch to the Root User

The commands below use `sudo`. If you prefer to run them as root:

```bash
sudo -i        # switch to root (login shell)
whoami         # verify: should print root
exit           # return to the ubuntu user when done
```

---

## Step 3: Install Prerequisites

The installer is a `.zip`, so make sure `curl` and `unzip` are available:

```bash
sudo apt-get update
sudo apt-get install -y curl unzip
```

---

## Step 4: Download the AWS CLI v2 Installer

For standard **x86_64 / AMD64** instances:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

For **ARM / Graviton** instances (e.g., `t4g`, `m7g`):

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
```

> Not sure which one? Run `uname -m`. `x86_64` = use the first URL, `aarch64` = use the ARM URL.

---

## Step 5: Unzip and Run the Installer

```bash
unzip awscliv2.zip
sudo ./aws/install
```

---

## Step 6: Verify the Installation

```bash
aws --version
```

Expected output (version will vary):

```
aws-cli/2.x.x Python/3.x.x Linux/x86_64
```

---

## Step 7: Configure Credentials

You have two common options on EC2.

### Option A (Recommended): Use an IAM Role

Attach an IAM role to the EC2 instance (via the AWS Console or `aws ec2 associate-iam-instance-profile`). The CLI automatically picks up temporary credentials from the instance metadata — no keys to store on disk.

Verify it works:

```bash
aws sts get-caller-identity
```

### Option B: Configure Access Keys Manually

Only use this if you cannot attach a role. Run:

```bash
aws configure
```

Then enter:

```
AWS Access Key ID [None]: <YOUR_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <YOUR_SECRET_ACCESS_KEY>
Default region name [None]: us-east-1
Default output format [None]: json
```

Verify:

```bash
aws sts get-caller-identity
```

> Security note: Prefer IAM roles over long-lived access keys. If you must use keys, never commit them to git and rotate them regularly.

---

## Updating the AWS CLI Later

Re-run the installer with the `--update` flag:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
aws --version
```

---

## Cleanup (Optional)

Remove the downloaded installer files:

```bash
rm -rf awscliv2.zip aws/
```

---

## Quick Reference

```bash
# Install prerequisites
sudo apt-get update && sudo apt-get install -y curl unzip

# Download (x86_64)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install
unzip awscliv2.zip && sudo ./aws/install

# Verify
aws --version
aws sts get-caller-identity
```
