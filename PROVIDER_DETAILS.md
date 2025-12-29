# Workload Identity Provider Details

When creating the OIDC provider in Google Cloud Console, use these exact details:

## Provider Configuration

### Basic Information
- **Provider type:** `OpenID Connect (OIDC)`
- **Provider name:** `github-provider`
- **Display name:** `GitHub Provider` (or any name you prefer)

### Issuer URL
```
https://token.actions.githubusercontent.com
```

### Attribute Mapping
Add these **3 attribute mappings**:

| Google Attribute | OIDC Claim |
|-----------------|------------|
| `google.subject` | `assertion.sub` |
| `attribute.actor` | `assertion.actor` |
| `attribute.repository` | `assertion.repository` |

### Attribute Condition (REQUIRED)
Add this condition to restrict access to your repository:
```
assertion.repository=="wedecor/ReachMuslims"
```

**Important:** This condition must reference one of the mapped attributes (in this case, `assertion.repository`).

### Allowed Audiences (Optional)
Leave this **empty** or use:
```
https://github.com/wedecor
```

## Step-by-Step in Console

1. **Provider type:** Select **OpenID Connect (OIDC)**

2. **Provider name:** Enter `github-provider`

3. **Display name:** Enter `GitHub Provider`

4. **Issuer URL:** Enter exactly:
   ```
   https://token.actions.githubusercontent.com
   ```

5. **Attribute mapping:** Click **ADD MAPPING** three times and add:
   - First mapping:
     - **Google attribute:** `google.subject`
     - **OIDC claim:** `assertion.sub`
   
   - Second mapping:
     - **Google attribute:** `attribute.actor`
     - **OIDC claim:** `assertion.actor`
   
   - Third mapping:
     - **Google attribute:** `attribute.repository`
     - **OIDC claim:** `assertion.repository`

6. **Attribute condition** (REQUIRED - this fixes the error):
   - In the **Attribute condition** field, enter:
     ```
     assertion.repository=="wedecor/ReachMuslims"
     ```
   - This condition must reference one of the mapped attributes (`assertion.repository`)

7. **Allowed audiences:** Leave empty (or add `https://github.com/wedecor`)

8. Click **SAVE**

## Visual Guide

```
┌─────────────────────────────────────────┐
│ Provider Configuration                   │
├─────────────────────────────────────────┤
│ Provider type: OpenID Connect (OIDC)    │
│ Provider name: github-provider          │
│ Display name: GitHub Provider           │
│ Issuer URL:                             │
│   https://token.actions.githubusercontent.com │
│                                         │
│ Attribute Mapping:                      │
│   google.subject = assertion.sub        │
│   attribute.actor = assertion.actor     │
│   attribute.repository = assertion.repository │
│                                         │
│ Allowed audiences: (leave empty)        │
└─────────────────────────────────────────┘
```

## Important Notes

✅ **Issuer URL must be exact:** `https://token.actions.githubusercontent.com`  
✅ **Attribute mappings are case-sensitive**  
✅ **All 3 mappings are required**  
✅ **Provider name can be anything, but `github-provider` is recommended**

## After Creating

Once created, you'll get a **Resource name** that looks like:
```
projects/123456789012/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

This is what you'll use for the `WIF_PROVIDER` GitHub secret.

