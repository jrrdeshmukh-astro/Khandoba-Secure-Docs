#!/usr/bin/env python3
"""
Generate Apple OAuth Client Secret JWT for Supabase

This script generates a JWT token that serves as the OAuth client secret
for Sign in with Apple integration with Supabase.

Requirements:
    pip install PyJWT cryptography

Usage:
    python3 generate_apple_oauth_secret.py --service-id YOUR_SERVICE_ID
    
    Or with custom values:
    python3 generate_apple_oauth_secret.py \\
      --team-id Q5Y8754WU4 \\
      --key-id PR62QK662L \\
      --service-id com.khandoba.securedocs \\
      --key-path ../AuthKey_PR62QK662L.p8
"""

import argparse
import time
import jwt
from datetime import datetime, timedelta
from pathlib import Path
import sys

# Default values from your AppConfig
DEFAULT_TEAM_ID = "Q5Y8754WU4"
DEFAULT_KEY_ID = "PR62QK662L"
DEFAULT_KEY_PATH = "../AuthKey_PR62QK662L.p8"  # Relative to scripts directory
DEFAULT_SERVICE_ID = "com.khandoba.securedocs.supabase"  # You'll need to create this in Apple Developer Portal

def generate_apple_oauth_secret(team_id: str, key_id: str, service_id: str, key_path: str) -> str:
    """
    Generate Apple OAuth client secret JWT.
    
    Args:
        team_id: Your Apple Developer Team ID
        key_id: Your Apple Sign-In Key ID
        service_id: Your Service ID (Client ID) - must be created in Apple Developer Portal
        key_path: Path to your .p8 private key file
    
    Returns:
        JWT token string to use as OAuth client secret
    """
    # Read the private key
    key_file = Path(key_path)
    if not key_file.exists():
        # Try absolute path from project root
        script_dir = Path(__file__).parent.parent
        key_file = script_dir / "AuthKey_PR62QK662L.p8"
        if not key_file.exists():
            raise FileNotFoundError(f"Private key file not found: {key_path}. Tried: {key_file}")
    
    with open(key_file, 'r') as f:
        private_key = f.read()
    
    # Current time
    now = datetime.utcnow()
    iat = int(now.timestamp())
    
    # Expiration: 6 months from now (maximum allowed by Apple)
    exp = int((now + timedelta(days=180)).timestamp())
    
    # JWT Header
    headers = {
        "alg": "ES256",
        "kid": key_id
    }
    
    # JWT Payload
    payload = {
        "iss": team_id,  # Issuer: Your Team ID
        "iat": iat,      # Issued at: Current time
        "exp": exp,      # Expiration: 6 months from now
        "aud": "https://appleid.apple.com",  # Audience: Apple's OAuth endpoint
        "sub": service_id  # Subject: Your Service ID (Client ID)
    }
    
    # Generate JWT
    token = jwt.encode(
        payload,
        private_key,
        algorithm="ES256",
        headers=headers
    )
    
    return token

def main():
    parser = argparse.ArgumentParser(
        description="Generate Apple OAuth Client Secret JWT for Supabase",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Use defaults (requires Service ID to be set in script)
  python3 generate_apple_oauth_secret.py --service-id com.khandoba.securedocs.supabase
  
  # Specify all parameters
  python3 generate_apple_oauth_secret.py \\
    --team-id Q5Y8754WU4 \\
    --key-id PR62QK662L \\
    --service-id com.khandoba.securedocs \\
    --key-path ../AuthKey_PR62QK662L.p8
        """
    )
    
    parser.add_argument(
        "--team-id",
        default=DEFAULT_TEAM_ID,
        help=f"Apple Developer Team ID (default: {DEFAULT_TEAM_ID})"
    )
    
    parser.add_argument(
        "--key-id",
        default=DEFAULT_KEY_ID,
        help=f"Apple Sign-In Key ID (default: {DEFAULT_KEY_ID})"
    )
    
    parser.add_argument(
        "--service-id",
        default=None,
        required=True,
        help="Service ID (Client ID) - REQUIRED. Create in Apple Developer Portal first."
    )
    
    parser.add_argument(
        "--key-path",
        default=DEFAULT_KEY_PATH,
        help=f"Path to .p8 private key file (default: {DEFAULT_KEY_PATH})"
    )
    
    args = parser.parse_args()
    
    try:
        print("🔐 Generating Apple OAuth Client Secret JWT...")
        print(f"   Team ID: {args.team_id}")
        print(f"   Key ID: {args.key_id}")
        print(f"   Service ID: {args.service_id}")
        print(f"   Key Path: {args.key_path}\n")
        
        token = generate_apple_oauth_secret(
            team_id=args.team_id,
            key_id=args.key_id,
            service_id=args.service_id,
            key_path=args.key_path
        )
        
        print("✅ Success! Your OAuth Client Secret JWT:\n")
        print("=" * 80)
        print(token)
        print("=" * 80)
        print("\n📋 Next Steps:")
        print("   1. Copy the JWT token above")
        print("   2. Go to Supabase Dashboard > Authentication > Providers > Apple")
        print("   3. Paste the JWT into the 'Secret Key (for OAuth)' field")
        print("   4. Enter your Service ID in the 'Client IDs' field")
        print("   5. Click Save")
        print("\n⚠️  IMPORTANT:")
        print("   - This token expires in 6 months")
        print("   - You'll need to regenerate it before expiration")
        print("   - Set a reminder to regenerate in 5 months")
        
    except FileNotFoundError as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        print("\n💡 Tip: Make sure the .p8 key file is in the project root or specify the path with --key-path", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error generating JWT: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
