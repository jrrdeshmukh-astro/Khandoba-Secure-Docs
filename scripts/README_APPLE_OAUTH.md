# Apple OAuth Client Secret Generator

This script generates the JWT token needed for Apple Sign-In OAuth configuration in Supabase.

## Prerequisites

Install required Python packages:

```bash
pip3 install PyJWT cryptography
```

## Quick Start

1. **Create a Service ID in Apple Developer Portal** (if you haven't already):
   - Go to https://developer.apple.com/account/resources/identifiers/list/serviceId
   - Click "+" to create a new Service ID
   - Description: "Khandoba Secure Docs - Supabase"
   - Identifier: `com.khandoba.securedocs.supabase` (or similar)
   - Enable "Sign in with Apple"
   - Configure return URL: `https://oqlffmhlirjfeevqhbio.supabase.co/auth/v1/callback`
   - Save and note the Service ID identifier

2. **Install dependencies** (if not already installed):
   ```bash
   pip3 install PyJWT cryptography
   ```

3. **Run the script**:
   ```bash
   cd scripts
   python3 generate_apple_oauth_secret.py --service-id YOUR_SERVICE_ID
   ```

   Replace `YOUR_SERVICE_ID` with the Service ID you created in step 1.

4. **Copy the generated JWT token** and paste it into Supabase:
   - Go to Supabase Dashboard > Authentication > Providers > Apple
   - Paste the JWT into "Secret Key (for OAuth)" field
   - Enter your Service ID in "Client IDs" field
   - Click Save

## Default Values

The script uses these defaults from your AppConfig:
- **Team ID**: `Q5Y8754WU4`
- **Key ID**: `PR62QK662L`
- **Key Path**: `../AuthKey_PR62QK662L.p8` (relative to scripts directory)

You only need to specify the **Service ID** (which you create in Apple Developer Portal).

## Full Example

```bash
cd scripts
python3 generate_apple_oauth_secret.py \
  --team-id Q5Y8754WU4 \
  --key-id PR62QK662L \
  --service-id com.khandoba.securedocs.supabase \
  --key-path ../AuthKey_PR62QK662L.p8
```

## Important Notes

⚠️ **Token Expiration**: The JWT token expires in 6 months. You must regenerate it before expiration or users won't be able to sign in.

📅 **Set a Reminder**: Regenerate the token in 5 months to avoid service interruption.

🔐 **Security**: Keep your `.p8` private key file secure. Never commit it to git or share it publicly.

## Troubleshooting

### "Private key file not found"
- Make sure `AuthKey_PR62QK662L.p8` is in the project root directory
- Or specify the full path with `--key-path`

### "Invalid Service ID"
- Make sure you've created the Service ID in Apple Developer Portal
- The Service ID must have "Sign in with Apple" enabled
- The return URL must be configured correctly

### "Module not found: jwt" or "Module not found: cryptography"
- Install dependencies: `pip3 install PyJWT cryptography`

## Example Output

```
🔐 Generating Apple OAuth Client Secret JWT...
   Team ID: Q5Y8754WU4
   Key ID: PR62QK662L
   Service ID: com.khandoba.securedocs.supabase
   Key Path: ../AuthKey_PR62QK662L.p8

✅ Success! Your OAuth Client Secret JWT:

================================================================================
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlBSNjJRSzY2MkwifQ.eyJpc3MiOiJR...
================================================================================

📋 Next Steps:
   1. Copy the JWT token above
   2. Go to Supabase Dashboard > Authentication > Providers > Apple
   3. Paste the JWT into the 'Secret Key (for OAuth)' field
   4. Enter your Service ID in the 'Client IDs' field
   5. Click Save

⚠️  IMPORTANT:
   - This token expires in 6 months
   - You'll need to regenerate it before expiration
   - Set a reminder to regenerate in 5 months
```
