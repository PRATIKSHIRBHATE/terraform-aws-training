# Install Docker on an Ubuntu EC2 Instance

This guide installs Docker on an Ubuntu EC2 instance using the distribution's `docker.io` package. This is the quickest way to get Docker running and is well-suited for training and lab environments.

> Note: `docker.io` (from Ubuntu's universe repo) is convenient but is usually an older version than Docker's official Docker CE packages. For a lab this is fine. If you need the latest Docker CE, use Docker's official APT repository instead.

## Prerequisites

- An Ubuntu EC2 instance (22.04, 24.04, or newer)
- SSH access to the instance
- `sudo` or root privileges
- Internet access from the instance

---

## Step 1: Connect to the EC2 Instance

```bash
ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

---

## Step 2: (Optional) Switch to the Root User

The commands below are shown as root (no `sudo`). If you are logged in as `ubuntu`, either switch to root or prefix each command with `sudo`.

```bash
sudo -i        # switch to root (login shell)
whoami         # verify: should print root
```

---

## Step 3: Install Docker

```bash
apt update
apt install -y docker.io
systemctl enable docker.service --now
docker --version
```

What each command does:

- `apt update` — refreshes the package index
- `apt install -y docker.io` — installs the Docker Engine package
- `systemctl enable docker.service --now` — enables Docker to start on boot and starts it immediately
- `docker --version` — confirms the installation

> If you are running as the `ubuntu` user rather than root, prefix each command with `sudo`, e.g. `sudo apt update`.

---

## Step 4: Verify Docker Is Running

```bash
systemctl status docker      # should show "active (running)"
docker info                  # shows engine details
docker run hello-world       # pulls and runs a test container
```

A successful `hello-world` run confirms Docker can pull images and run containers.

---

## Step 5: (Optional) Run Docker as a Non-Root User

By default, Docker commands require root or `sudo`. To let a normal user (e.g. `ubuntu`) run Docker without `sudo`, add them to the `docker` group:

```bash
usermod -aG docker ubuntu     # add the ubuntu user to the docker group
```

Then log out and back in (or run `newgrp docker`) for the group change to take effect. Verify:

```bash
docker ps                     # should work without sudo
```

> Security note: Members of the `docker` group effectively have root-equivalent access on the host. Only add trusted users.

---

## Common Docker Commands

```bash
docker images                 # list local images
docker ps                     # list running containers
docker ps -a                  # list all containers (including stopped)
docker pull nginx             # download an image
docker run -d -p 80:80 nginx  # run nginx in the background, mapped to port 80
docker stop <container_id>    # stop a container
docker rm <container_id>      # remove a container
docker rmi <image_id>         # remove an image
```

---

## Quick Reference

```bash
apt update
apt install -y docker.io
systemctl enable docker.service --now
docker --version
docker run hello-world
```
