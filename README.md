# gandi-dynamic-dns-update

Updates your GANDI DNS `A` record to match your public IP address, acting as a dynamic DNS provider. Installs a `systemd` timer that periodically checks your public IP and updates the DNS record if it has changed.

## Prerequisites

1. **GANDI Personal Access Token (PAT):**
   - Go to <https://admin.gandi.net/organizations/>
   - Select your organization
   - Under "Personal Access Token (PAT)", click **Create Token**
   - Save the token for later use

## Installation

1. Clone the repository to your machine.
2. Run the following command to install the script and systemd service:

   ```bash
   make install
   ```

## Configuration

- The config file is located at `~/.config/gandi-dns-update/config.toml`.
- Set the following in the config file:
  - **domain**: Your domain name (e.g., `example.com`)
  - **api_key**: Your GANDI Personal Access Token (PAT)

## Usage

The systemd timer will automatically run the update process every 5 minutes. To manually trigger the script, use:

```bash
make run
```