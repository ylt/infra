# Ubuntu Upgrade Runbook

Upgrading from Ubuntu Lunar (23.04 - EOL) to Ubuntu 24.04 LTS (Noble Numbat)

## Pre-requisites

- Backup important data (especially Nomad/Consul/Vault data if not already backed up)
- SSH access to all nodes
- Time to perform upgrades (estimate 30-60 minutes per node)

## Node List

Based on `ansible/new/hosts`:
- ubuntu-node-1 (192.168.7.128) - Master node
- ubuntu-node-2 (192.168.7.129) - Worker node
- ubuntu-node-3 (192.168.7.81) - Worker node
- ubuntu-node-4 (192.168.7.136) - Worker node
- node-5 (192.168.6.188) - Worker node
- node-6 (192.168.7.122) - Worker node

## Upgrade Strategy

**Recommended order:**
1. Worker nodes first (node-6, node-5, ubuntu-node-4, ubuntu-node-3, ubuntu-node-2)
2. Master node last (ubuntu-node-1)

This allows Nomad/Consul/Vault services to remain operational during worker upgrades.

---

## Upgrade Steps (Run on each node)

### Step 1: Fix EOL Repository Issues

Since Lunar is EOL, we need to point to the old-releases archive:

```bash
# SSH into the node
ssh ubuntu-node-X  # Replace X with node number

# Become root
sudo -i

# Backup current sources
cp /etc/apt/sources.list /etc/apt/sources.list.backup
cp -r /etc/apt/sources.list.d /etc/apt/sources.list.d.backup

# Replace lunar repos with old-releases
sed -i -e 's|http://ports.ubuntu.com/ubuntu-ports|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list
sed -i -e 's|http://archive.ubuntu.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list

# Also fix HashiCorp repo (remove it temporarily)
mv /etc/apt/sources.list.d/hashicorp.list /etc/apt/sources.list.d/hashicorp.list.disabled 2>/dev/null || true

# Update package lists
apt update
```

### Step 2: Upgrade Current Packages

```bash
# Upgrade all packages on current release
apt upgrade -y

# Perform dist-upgrade
apt dist-upgrade -y

# Remove unnecessary packages
apt autoremove -y
apt autoclean
```

### Step 3: Upgrade to Ubuntu Mantic (23.10)

```bash
# Install update manager
apt install -y update-manager-core

# Edit release upgrader config to allow normal releases
sed -i 's/Prompt=.*/Prompt=normal/g' /etc/update-manager/release-upgrades

# Run the release upgrader (this is interactive)
do-release-upgrade

# Follow the prompts:
# - Press 'y' to confirm
# - Review changes
# - Accept defaults unless you have specific requirements
# - May need to restart services - generally safe to accept
# - Reboot when prompted
```

**After reboot, SSH back in and verify:**
```bash
lsb_release -a
# Should show Ubuntu 23.10 (Mantic Minotaur)
```

### Step 4: Upgrade to Ubuntu Noble (24.04 LTS)

```bash
# SSH back into the node
ssh ubuntu-node-X

# Become root
sudo -i

# Run the release upgrader again
do-release-upgrade

# Follow the prompts again
# Reboot when prompted
```

**After reboot, verify:**
```bash
lsb_release -a
# Should show Ubuntu 24.04 LTS (Noble Numbat)
```

### Step 5: Post-Upgrade Cleanup

```bash
# Update all packages
apt update
apt upgrade -y

# Reinstall HashiCorp repo if needed for Nomad/Consul/Vault
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update

# Verify Nomad/Consul services (if running)
systemctl status nomad
systemctl status consul

# Clean up
apt autoremove -y
apt autoclean
```

---

## Alternative: Clean Install Approach

If upgrades fail or you encounter issues, consider clean reinstalling Ubuntu 24.04 LTS:

### For Worker Nodes:
1. Drain the Nomad node: `nomad node drain -enable <node-id>`
2. Backup any local data
3. Reinstall Ubuntu 24.04 LTS from ISO/netboot
4. Restore configuration
5. Rejoin to Nomad/Consul cluster

### For Master Node:
**⚠️ CRITICAL:** Ensure Consul/Vault data is backed up before proceeding!

1. Take snapshot of Consul: `consul snapshot save backup.snap`
2. Backup Vault data
3. Consider promoting another node to server temporarily
4. Reinstall Ubuntu 24.04 LTS
5. Restore services

---

## Verification Checklist

After upgrading each node, verify:

- [ ] Ubuntu version: `lsb_release -a` shows 24.04 LTS
- [ ] Network connectivity: Can ping other nodes
- [ ] Docker running: `docker ps`
- [ ] Nomad client/server running: `systemctl status nomad`
- [ ] Consul running: `systemctl status consul`
- [ ] Vault running (on master): `systemctl status vault`
- [ ] Disk space available: `df -h`
- [ ] No errors in logs: `journalctl -xe`

---

## Rollback Plan

If upgrade fails:

1. **Before upgrade:** Have backup/snapshots ready
2. **During upgrade:** If `do-release-upgrade` fails, you can usually fix packages and retry
3. **After bad upgrade:**
   - Boot from rescue media
   - Restore from backup
   - Or perform clean install

---

## Timeline Estimate

- Worker node upgrade: ~45-60 minutes each
- Master node upgrade: ~60-90 minutes (including verification)
- **Total for 6 nodes: 6-8 hours** (if done sequentially)

Can be parallelized for workers (do 2-3 at once) to reduce total time to ~3-4 hours.

---

## Notes

- **Important:** Ubuntu Lunar → Noble requires intermediate upgrade through Mantic (23.10)
- Direct upgrade from 23.04 to 24.04 LTS is not supported
- Consider scheduling during maintenance window
- Keep Nomad cluster operational by upgrading workers first
- Test on one worker node before proceeding with others
