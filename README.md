# Bulk Service Manager

This Bash script is designed to manage system services on a Linux machine using `systemctl`. It allows you to enable, disable, start, stop, and check the status of specified services. The script is intended to be run as the root user.

## Features

- Manage multiple services at once.
- Check the status of services.
- Handles both default services and user-specified services.

## Prerequisites

- This script must be run on a Linux system with `systemd`.
- You need to have root privileges to manage services.

## Compatibility

This script works best with `systemd` 252 (252.33-1). For optimal performance and compatibility, ensure your system is running this version or later.

## Usage

To use the script, run it with one of the following actions and specify the services you want to manage:

```bash
./service_manager.sh {action} [service1 service2 ...]
```
Where `{action}` can be one of the following:

- `enable`: Start the specified services.
- `disable`: Stop and disable the specified services.
- `start`: Start the specified services.
- `stop`: Stop the specified services.
- `enstart`: Enable and start the specified services
- `distop`: Stop and disable the specified services.
- `status`: Check the status of the specified services.

> **Note:**  
> This script includes a default services array (line 35). If you don't want to specify services as arguments, you can add them by editing the `default_svcs` array in this script.

## Example

To start the default services:

```bash
./service_manager.sh start
```
To check the status of a specific service:

```bash
./service_manager.sh status specific-service
```
To enable and start an additional service:

```bash
./service_manager.sh enstart additional-service
```
