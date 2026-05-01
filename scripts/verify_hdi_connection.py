#!/usr/bin/env python3
"""
Quick HANA HDI Connection Test

This script tests the HANA connection with HDI Runtime User credentials
BEFORE deploying to SAP AI Core.

Usage:
    python verify_hdi_connection.py

Requirements:
    pip install hdbcli
"""

import sys
import os
from hdbcli import dbapi

# ANSI colors for output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color


def print_header(text):
    print(f"\n{BLUE}{'=' * 60}{NC}")
    print(f"{BLUE}{text.center(60)}{NC}")
    print(f"{BLUE}{'=' * 60}{NC}\n")


def print_success(text):
    print(f"{GREEN}✓ {text}{NC}")


def print_error(text):
    print(f"{RED}✗ {text}{NC}")


def print_info(text):
    print(f"{YELLOW}ℹ {text}{NC}")


def get_credentials():
    """Get HANA credentials from user input."""
    print_header("HANA HDI Connection Test")

    print(f"{YELLOW}Please enter your HANA HDI credentials:{NC}")
    print(f"{YELLOW}(Copy from BTP Service Key 'hdi-container'){NC}\n")

    host = input("Host (e.g., *.hana.prod-*.hanacloud.ondemand.com): ").strip()
    port = input("Port (default: 443): ").strip() or "443"
    user = input("User (HDI Runtime User with _RT suffix): ").strip()
    password = input("Password: ").strip()

    if not all([host, port, user, password]):
        print_error("All fields are required!")
        sys.exit(1)

    return {
        'host': host,
        'port': int(port),
        'user': user,
        'password': password
    }


def test_connection(credentials):
    """Test HANA connection with provided credentials."""
    print_header("Testing Connection")

    print_info(f"Host: {credentials['host']}")
    print_info(f"Port: {credentials['port']}")
    print_info(f"User: {credentials['user'][:30]}...")
    print_info("Password: ***hidden***\n")

    try:
        print("Attempting to connect...")
        connection = dbapi.connect(
            address=credentials['host'],
            port=credentials['port'],
            user=credentials['user'],
            password=credentials['password'],
            encrypt=True,
            sslValidateCertificate=False
        )

        print_success("Connection established!")

        # Test 1: Get current schema
        print("\n" + "-" * 60)
        print(f"{BLUE}Test 1: Current Schema{NC}")
        cursor = connection.cursor()
        cursor.execute("SELECT CURRENT_SCHEMA FROM DUMMY")
        current_schema = cursor.fetchone()[0]
        print_success(f"Current schema: {current_schema}")

        # Test 2: List available schemas
        print("\n" + "-" * 60)
        print(f"{BLUE}Test 2: Available Schemas{NC}")
        cursor.execute("""
            SELECT SCHEMA_NAME
            FROM SYS.SCHEMAS
            WHERE HAS_PRIVILEGES = 'TRUE'
            ORDER BY SCHEMA_NAME
        """)
        schemas = cursor.fetchall()
        print_success(f"You have access to {len(schemas)} schema(s):")
        for schema in schemas[:10]:  # Show first 10
            print(f"  - {schema[0]}")
        if len(schemas) > 10:
            print(f"  ... and {len(schemas) - 10} more")

        # Test 3: Check for expected table
        print("\n" + "-" * 60)
        print(f"{BLUE}Test 3: Check EXPENSE_MANAGEMENT_EXPENSEHEADER Table{NC}")
        try:
            cursor.execute("""
                SELECT COUNT(*)
                FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
            """)
            count = cursor.fetchone()[0]
            print_success(f"Table found! Contains {count} record(s)")

            # Show sample record
            if count > 0:
                cursor.execute("""
                    SELECT ID, EXPENSEID, STATUS, TOTALAMOUNT, CURRENCY
                    FROM "EXPENSE_MANAGEMENT_EXPENSEHEADER"
                    LIMIT 1
                """)
                sample = cursor.fetchone()
                print_info("Sample record:")
                print(f"  ID: {sample[0]}")
                print(f"  EXPENSEID: {sample[1]}")
                print(f"  STATUS: {sample[2]}")
                print(f"  TOTALAMOUNT: {sample[3]}")
                print(f"  CURRENCY: {sample[4]}")

        except Exception as e:
            print_error(f"Table not found in current schema!")
            print_error(f"Error: {str(e)}")
            print_info("You may need to:")
            print_info("  1. Use fully qualified table name: \"SCHEMA\".\"TABLE\"")
            print_info("  2. Grant HDI user access to the schema")
            print_info("  3. Deploy your data model to HDI container")

        # Test 4: Test write permission
        print("\n" + "-" * 60)
        print(f"{BLUE}Test 4: Test Write Permission (DUMMY UPDATE){NC}")
        try:
            # Just test if we can execute UPDATE (won't actually update anything)
            cursor.execute("SELECT 1 FROM DUMMY WHERE 1=0")
            print_success("Read permission verified")

            # Note: We won't actually test write without user confirmation
            print_info("Write test skipped (requires actual table modification)")

        except Exception as e:
            print_error(f"Permission test failed: {str(e)}")

        # Close connection
        cursor.close()
        connection.close()

        # Final summary
        print_header("Connection Test Summary")
        print_success("✓ Connection successful!")
        print_success("✓ SSL encryption enabled")
        print_success(f"✓ Connected to schema: {current_schema}")
        print_success(f"✓ Access to {len(schemas)} schema(s)")

        print(f"\n{GREEN}╔════════════════════════════════════════════════════════╗{NC}")
        print(f"{GREEN}║  Your HDI credentials are working correctly! 🎉       ║{NC}")
        print(f"{GREEN}╚════════════════════════════════════════════════════════╝{NC}\n")

        print(f"{YELLOW}Next steps:{NC}")
        print("  1. Run ./recreate-secret-hdi.sh to create Secret in AI Core")
        print("  2. Create a new execution in SAP AI Core")
        print("  3. Monitor logs for 'Successfully connected to SAP HANA'\n")

        return True

    except Exception as e:
        print_error(f"Connection failed: {str(e)}")

        print(f"\n{RED}╔════════════════════════════════════════════════════════╗{NC}")
        print(f"{RED}║  Connection Failed - See Troubleshooting Below        ║{NC}")
        print(f"{RED}╚════════════════════════════════════════════════════════╝{NC}\n")

        print(f"{YELLOW}Common issues:{NC}")
        print("  1. Wrong host/port:")
        print("     - Check BTP Service Key for correct values")
        print("     - HANA Cloud uses port 443 by default")
        print("")
        print("  2. Authentication failed:")
        print("     - Verify HDI Runtime User credentials")
        print("     - User should have format: *_RT")
        print("     - Password copied correctly from Service Key")
        print("")
        print("  3. Network/SSL issues:")
        print("     - Ensure HANA Cloud instance is running")
        print("     - Check firewall/IP allowlist")
        print("     - SSL must be enabled (encrypt=True)")
        print("")
        print("  4. Missing hdbcli library:")
        print("     - Run: pip install hdbcli")
        print("")
        print(f"{YELLOW}See HDI_CONNECTION_TROUBLESHOOTING.md for detailed help{NC}\n")

        return False


def main():
    """Main entry point."""
    try:
        credentials = get_credentials()
        success = test_connection(credentials)

        sys.exit(0 if success else 1)

    except KeyboardInterrupt:
        print(f"\n\n{YELLOW}Test cancelled by user{NC}")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
