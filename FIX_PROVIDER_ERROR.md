# Fix: Attribute Condition Error

If you see this error:
> "The attribute condition must reference one of the provider's claims"

## Solution

When creating the Workload Identity Provider, you **must add an Attribute Condition** that references one of your mapped attributes.

### Step-by-Step Fix

1. **Go back to your provider:**
   - https://console.cloud.google.com/iam-admin/workload-identity-pools?project=reach-muslim-leads
   - Click on `github-actions-pool`
   - Click on `github-provider` (or edit if it exists)

2. **Find the "Attribute condition" field**

3. **Add this condition:**
   ```
   assertion.repository=="wedecor/ReachMuslims"
   ```

4. **Important:** The condition must:
   - Reference `assertion.repository` (one of your mapped attributes)
   - Use double equals `==` for comparison
   - Match your GitHub repository exactly: `wedecor/ReachMuslims`

5. **Click SAVE**

## Why This Is Required

The attribute condition restricts which GitHub repositories can use this provider. Without it, Google Cloud doesn't know which repositories are allowed, causing the error.

## Alternative Conditions

If you want to allow multiple repositories, you can use:

**Allow specific repositories:**
```
assertion.repository=="wedecor/ReachMuslims" || assertion.repository=="wedecor/OtherRepo"
```

**Allow all repositories in your organization:**
```
assertion.repository.startsWith("wedecor/")
```

**Allow any repository (less secure):**
```
true
```

## Complete Provider Configuration

Here's the complete configuration that should work:

```
Provider type: OpenID Connect (OIDC)
Provider name: github-provider
Display name: GitHub Provider
Issuer URL: https://token.actions.githubusercontent.com

Attribute Mappings:
1. google.subject = assertion.sub
2. attribute.actor = assertion.actor
3. attribute.repository = assertion.repository

Attribute Condition:
assertion.repository=="wedecor/ReachMuslims"

Allowed Audiences: (leave empty)
```

## After Adding the Condition

1. Save the provider
2. Continue with Step 6 in the setup guide (linking to service account)
3. The error should be resolved!

