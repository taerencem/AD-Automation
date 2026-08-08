# OU Cleanup Script Guide

This script identifies stale Active Directory objects and moves them to a quarantine OU for review.

## Usage

```powershell
.\OU-Cleanup.ps1 -QuarantineOU "OU=Quarantine,DC=yourdomain,DC=com" -InactiveDays 90
