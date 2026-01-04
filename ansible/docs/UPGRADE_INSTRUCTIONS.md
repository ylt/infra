# Ubuntu Upgrade - Ansible Automation

## Quick Start

```bash
cd /Users/joe/projects/infra/nomad/ansible/new
```

## Recommended Upgrade Order

### 1. Test on ONE worker node first
```bash
ansible-playbook ubuntu-upgrade.yml --limit ubuntu-node-2
```
**Wait for completion, verify it works before proceeding!**

### 2. Upgrade remaining workers (one at a time)
```bash
ansible-playbook ubuntu-upgrade.yml --limit ubuntu-node-3
ansible-playbook ubuntu-upgrade.yml --limit ubuntu-node-4
ansible-playbook ubuntu-upgrade.yml --limit node-5
ansible-playbook ubuntu-upgrade.yml --limit node-6
```

### 3. Upgrade master node LAST
```bash
ansible-playbook ubuntu-upgrade.yml --limit ubuntu-node-1
```

## Alternative: Upgrade all workers at once (parallel)
```bash
# Upgrade all nodes EXCEPT the master
ansible-playbook ubuntu-upgrade.yml --limit '!ubuntu-node-1'
```

## What the playbook does:

1. ✅ Backs up apt sources
2. ✅ Fixes EOL repository URLs
3. ✅ Upgrades current packages
4. ✅ Upgrades Lunar → Mantic (23.10)
5. ✅ Reboots
6. ✅ Upgrades Mantic → Noble (24.04 LTS)
7. ✅ Reboots again
8. ✅ Restores HashiCorp repository
9. ✅ Verifies services (Nomad, Consul)

## Estimated time per node:
- **45-90 minutes** (includes 2 reboots)

## Monitoring progress:

The playbook will show progress and pause for confirmation before each node.

**To skip confirmations:**
```bash
ansible-playbook ubuntu-upgrade.yml --limit ubuntu-node-2 --extra-vars "ansible_play_hosts_all=1"
```

## Troubleshooting:

If a node upgrade fails:
```bash
# SSH to the node
ssh ubuntu-node-X

# Check what release it's on
lsb_release -a

# If stuck on Mantic, manually run:
sudo do-release-upgrade

# If packages are broken:
sudo apt --fix-broken install
sudo dpkg --configure -a
```

## After all upgrades complete:

Verify cluster health:
```bash
# Check Nomad cluster
export NOMAD_ADDR=http://192.168.7.128:4646
nomad node status

# Check Consul cluster
export CONSUL_HTTP_ADDR=http://192.168.7.128:8500
consul members
```

Then proceed with k3s installation:
```bash
ansible-playbook k3s-setup.yml
```
