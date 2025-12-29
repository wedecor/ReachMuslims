# Firestore Index Audit Report
## Comprehensive Index Analysis for Reach Muslim Lead Management App

**Date:** December 29, 2025  
**Status:** Analysis Complete

---

## QUERY ANALYSIS BY COLLECTION

### 1. LEADS COLLECTION

#### Query Patterns Identified:

**A. Sales User Queries (assignedTo filter)**
1. `assignedTo == userId` + `orderBy('updatedAt', DESC)`
   - **Status:** ✅ Index exists (just added)
   - **Index:** `assignedTo (ASC) + updatedAt (DESC)`

2. `assignedTo == userId` + `status == X` + `orderBy('updatedAt', DESC)`
   - **Status:** ✅ Index exists (just added)
   - **Index:** `assignedTo (ASC) + status (ASC) + updatedAt (DESC)`

3. `assignedTo == userId` + `status == X` (count query)
   - **Status:** ✅ Index exists
   - **Index:** `assignedTo (ASC) + status (ASC)`

4. `assignedTo == userId` + `region == X` (count query)
   - **Status:** ❌ **MISSING INDEX**
   - **Required:** `assignedTo (ASC) + region (ASC)`

5. `assignedTo == userId` + `createdAt >= startOfDay` + `createdAt < endOfDay` (count query)
   - **Status:** ❌ **MISSING INDEX**
   - **Required:** `assignedTo (ASC) + createdAt (ASC)`

6. `assignedTo == userId` + `createdAt >= startOfWeek` (count query)
   - **Status:** ❌ **MISSING INDEX**
   - **Required:** `assignedTo (ASC) + createdAt (ASC)`

**B. Admin Queries (region filter)**
7. `region == X` + `orderBy('createdAt', DESC)`
   - **Status:** ✅ Index exists
   - **Index:** `region (ASC) + createdAt (ASC)`

8. `region == X` + `status == X`
   - **Status:** ✅ Index exists
   - **Index:** `region (ASC) + status (ASC)`

9. `region == X` + `assignedTo == X` (count query)
   - **Status:** ❌ **MISSING INDEX**
   - **Required:** `region (ASC) + assignedTo (ASC)`

10. `region == X` + `createdAt >= startOfDay` + `createdAt < endOfDay` (count query)
    - **Status:** ❌ **MISSING INDEX**
    - **Required:** `region (ASC) + createdAt (ASC)`

11. `region == X` + `createdAt >= startOfWeek` (count query)
    - **Status:** ❌ **MISSING INDEX**
    - **Required:** `region (ASC) + createdAt (ASC)`

**C. Date Range Queries**
12. `createdFrom <= createdAt <= createdTo` + `orderBy('createdAt', DESC)`
    - **Status:** ⚠️ **PARTIAL** - Needs specific combinations
    - **Note:** Depends on other filters (assignedTo or region)

**D. Search Queries**
13. `name >= lowerQuery` + `name < lowerQuery + '\uf8ff'` + `orderBy(...)`
    - **Status:** ❌ **MISSING INDEX**
    - **Required:** Multiple combinations needed:
      - `assignedTo (ASC) + name (ASC) + updatedAt (DESC)`
      - `region (ASC) + name (ASC) + createdAt (DESC)`
      - `region (ASC) + name (ASC) + updatedAt (DESC)`

**E. Admin AssignedTo Filter**
14. `assignedTo == X` + `orderBy('updatedAt', DESC)` (admin filtering by assigned user)
    - **Status:** ✅ Index exists (same as sales user)

15. `assignedTo == X` + `status == X` + `orderBy('updatedAt', DESC)` (admin)
    - **Status:** ✅ Index exists (same as sales user)

---

### 2. USERS COLLECTION

#### Query Patterns Identified:

1. `region == X` + `active == true` + `status == 'approved'`
   - **Status:** ✅ Index exists
   - **Index:** `region (ASC) + active (ASC) + status (ASC)`

2. `status == 'pending'` + `orderBy('createdAt', ASC)`
   - **Status:** ✅ Index exists
   - **Index:** `status (ASC) + createdAt (ASC)`

3. `status == 'approved'` + `orderBy('name', ASC)`
   - **Status:** ✅ Index exists
   - **Index:** `status (ASC) + name (ASC)`

**All user queries are covered! ✅**

---

### 3. NOTIFICATIONS COLLECTION

#### Query Patterns Identified:

1. `userId == X` + `orderBy('createdAt', DESC)`
   - **Status:** ✅ Index exists
   - **Index:** `userId (ASC) + createdAt (DESC)`

2. `userId == X` + `read == false`
   - **Status:** ❌ **MISSING INDEX**
   - **Required:** `userId (ASC) + read (ASC)`

**Note:** This query is used in `markAllAsRead()` - may not be critical if used infrequently.

---

### 4. FOLLOW-UPS (Subcollection)

#### Query Patterns Identified:

1. `orderBy('createdAt', DESC)` (no where clause)
   - **Status:** ✅ No index needed (single field orderBy)

**All follow-up queries are covered! ✅**

---

## SUMMARY OF MISSING INDEXES

### Critical (Will cause errors):
1. ❌ `assignedTo (ASC) + region (ASC)` - Sales user dashboard counts
2. ❌ `assignedTo (ASC) + createdAt (ASC)` - Sales user "created today/week" counts
3. ❌ `region (ASC) + assignedTo (ASC)` - Admin dashboard counts
4. ❌ `region (ASC) + createdAt (ASC)` - Admin "created today/week" counts

### Important (Search functionality):
5. ❌ `assignedTo (ASC) + name (ASC) + updatedAt (DESC)` - Sales user search
6. ❌ `region (ASC) + name (ASC) + createdAt (DESC)` - Admin search with date filter
7. ❌ `region (ASC) + name (ASC) + updatedAt (DESC)` - Admin search without date filter

### Low Priority (Infrequent use):
8. ❌ `userId (ASC) + read (ASC)` - Mark all notifications as read

---

## RECOMMENDED ACTIONS

### Immediate (Fix Errors):
Add indexes #1-4 to fix dashboard count queries.

### Soon (Improve UX):
Add indexes #5-7 to enable search functionality.

### Optional:
Add index #8 if "mark all as read" is frequently used.

---

## CURRENT INDEX STATUS

**Total Indexes:** 10  
**Missing Critical:** 4  
**Missing Important:** 3  
**Missing Optional:** 1

