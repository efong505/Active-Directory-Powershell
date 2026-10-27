# Active Directory PowerShell — server discovery and local password administration

PowerShell scripts for discovering Windows Server computer objects in Active Directory and **optionally changing the local account password** on each reachable computer through the legacy WinNT ADSI provider.

> **Safety:** These scripts can change real credentials. Run only with explicit authorization and a tested recovery procedure. Use an isolated lab first. This repository is not a substitute for Windows LAPS or centrally managed privileged-access controls.

## Files

- `get_servers.ps1` — queries Active Directory for server computer names and writes `servers.txt`; fails closed if discovery fails or finds no servers.
- `change_password_script.ps1` — validates an input list, skips unreachable hosts, prompts for a password per target, and writes a password-free results CSV.
- `servers_pass_change.ps1` — entry point; discovers servers unless `-InputFile` is provided.

## Usage

Run from Windows PowerShell in a permitted administrative environment with the ActiveDirectory module, network access, and sufficient rights to change the specified **local** account passwords.

**Review targets without making changes:**

```powershell
.\servers_pass_change.ps1 -WhatIf
```

**Use an explicitly reviewed server list (recommended):**

```powershell
.\servers_pass_change.ps1 -InputFile .\approved-servers.txt -WhatIf
```

**Execute against approved targets only (prompts per reachable computer):**

```powershell
.\servers_pass_change.ps1 -InputFile .\approved-servers.txt
```

The default account name is `Administrator`; specify `-LocalAccount` if an authorized environment uses a different local account name. Each target requires a confirmation through PowerShell's ShouldProcess mechanism unless `-Confirm:$false` is deliberately supplied to the lower-level script.

## Security and operational limitations

- The ADSI `WinNT://<computer>/<account>,user` provider targets a **local account**, not the AD computer-account password or a domain user's password.
- Password entry uses `Read-Host -AsSecureString`. The legacy ADSI `SetPassword` call requires a managed plaintext string, which cannot be deterministically zeroed. Unmanaged BSTR buffers are released with `ZeroFreeBSTR` in `finally` blocks. Avoid transcript logging, debugging, and running on untrusted hosts.
- ICMP reachability is only a preliminary check; a reachable host may still reject ADSI/RPC connections. Hosts without ICMP responses are skipped even if another management channel would work.
- `-WhatIf` still performs server discovery and reachability checks but does **not** request or change passwords.
- The script emits status only, not exception details or credentials. The CSV report may contain sensitive computer names; store it in an access-controlled directory.
- The default discovery filter is `*Server*` in the AD `OperatingSystem` attribute. Review the resulting target list before executing any password changes.
- The scripts have not been validated against a live Active Directory lab as part of this hardening. Do not assume compatibility with every OS, account policy, or environment.
- Prefer Windows LAPS for production local administrator password rotation. Password reuse, manual entry, and plaintext requirements make this legacy workflow unsuitable as a general-purpose enterprise password-rotation solution.
