import os
import tomllib
import requests
import argparse
import logging

# Default config paths
USER_CONFIG_PATH = os.path.expanduser('~/.config/gandi-dns-update/config.toml')
SYSTEM_CONFIG_PATH = '/etc/gandi-dns-update/config.toml'

# Argument parser for config path
parser = argparse.ArgumentParser(description='Update Gandi DNS with the public IP address.')
parser.add_argument('-c', '--config', type=str, help='Path to the config file.')
parser.add_argument('--quiet', action='store_true', help='Suppress info level log messages.')
args = parser.parse_args()

log_level = logging.INFO if not args.quiet else logging.ERROR
logging.basicConfig(level=log_level)
logger = logging.getLogger(__name__)

# Load configuration
def load_config():
    config_path = args.config or USER_CONFIG_PATH
    if not os.path.exists(config_path):
        config_path = SYSTEM_CONFIG_PATH if os.path.exists(SYSTEM_CONFIG_PATH) else None

    if config_path:
        with open(config_path, 'rb') as f:
            config = tomllib.load(f)
        if 'Gandi' not in config or 'domain' not in config['Gandi'] or 'api_key' not in config['Gandi']:
            logger.error("Config file missing required 'Gandi' section or keys.")
            raise ValueError("Config file is missing required keys.")
        return config['Gandi']['domain'], config['Gandi']['api_key']
    else:
        logger.error("Config file not found in user or system directories.")
        raise FileNotFoundError("Config file not found in user or system directories.")

GANDI_DOMAIN, GANDI_API_KEY = load_config()
API_URL = f'https://api.gandi.net/v5/livedns/domains/{GANDI_DOMAIN}/records/@'
AUTH_HEADER = {"Authorization": f"Bearer {GANDI_API_KEY}"}


def get_public_ip():
    try:
        response = requests.get('https://api.ipify.org')
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to get public IP: {e}")
        raise


def get_gandi_domain_records():
    try:
        response = requests.get(API_URL, headers=AUTH_HEADER)
        response.raise_for_status()
        rrsets = response.json()
        return {r["rrset_type"]: r["rrset_values"] for r in rrsets}
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to fetch DNS records from Gandi: {e}")
        raise
    except ValueError as e:
        logger.error(f"Failed to parse response from Gandi: {e}")
        raise


def set_gandi_domain_records(domain, api_key, records):
    data = {
        "items": [{"rrset_type": key, "rrset_values": value} for key, value in records.items()]
    }
    try:
        response = requests.put(API_URL, headers=AUTH_HEADER, json=data)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to update DNS records on Gandi: {e}")
        raise


def main():
    try:
        ip = get_public_ip()
        records = get_gandi_domain_records()
        if 'A' not in records or len(records['A']) == 0 or records['A'][0] != ip:
            logger.info("IP Address does not match. Updating...")
            records['A'] = [ip]
            set_gandi_domain_records(GANDI_DOMAIN, GANDI_API_KEY, records)
            logger.info("Update complete.")
        else:
            logger.info("IP Address is up-to-date. No update needed.")
    except Exception as e:
        logger.error(f"An error occurred: {e}")


if __name__ == '__main__':
    main()
