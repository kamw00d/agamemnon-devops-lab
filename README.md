# Agamemnon DevOps Lab

Agamemnon DevOps Lab is a hands-on infrastructure environment built to develop and demonstrate practical DevOps and cloud engineering skills.

The repository documents the gradual development of a reproducible lab: from Hyper-V virtual machine automation to application deployment, CI/CD, configuration management, infrastructure as code, and observability.

## Current scope

The current implementation provides PowerShell automation for:

- creating an Ubuntu Server template VM in Hyper-V;
- configuring its compute, network, firmware, and installation media;
- preparing and exporting the completed template;
- cloning new lab virtual machines from the exported system disk;
- excluding local VM artifacts, installation media, and secrets from version control.

## Automation flow

```text
Ubuntu Server ISO
        |
        v
Hyper-V template VM
        |
        v
Validated VM export
        |
        v
Cloned lab virtual machine
```

## Repository structure

```text
.
|-- Scripts/
|   |-- create-ubuntu-template.ps1
|   |-- export-ubuntu-template.ps1
|   `-- clone-ubuntu-vm.ps1
|-- .gitignore
`-- README.md
```

## Prerequisites

- Windows with the Hyper-V role enabled
- Windows PowerShell
- administrator privileges
- Ubuntu Server installation image
- an existing Hyper-V virtual switch

Configuration values such as VM names, paths, memory allocation, and virtual switch names are currently defined at the beginning of each script.

## Script workflow

1. Run `create-ubuntu-template.ps1` to create and configure the template VM.
2. Install and prepare Ubuntu Server inside the virtual machine.
3. Shut down the template and run `export-ubuntu-template.ps1`.
4. Run `clone-ubuntu-vm.ps1` to create a new lab VM from the exported disk.

## Repository safety

Virtual disks, ISO images, VM configuration files, exports, editor settings, environment files, logs, and temporary files are excluded through `.gitignore`.

No credentials or production configuration should be committed to this repository.

## Roadmap

- parameterize the existing PowerShell scripts;
- add post-clone system configuration;
- provision dedicated CI/CD and application hosts;
- introduce Docker-based application deployment;
- build CI/CD pipelines;
- add Ansible configuration management;
- add Terraform-managed cloud infrastructure;
- implement monitoring, logging, and operational documentation.

## Status

Active development and learning project. The lab will evolve alongside end-to-end DevOps and cloud portfolio projects.
