<div align="center">

```
 ,ggg, ,ggggggg,     ,ggggggg,  ,ggggggggggggggg  ,gggg,   ,ggggggggggg,              ,ggg, ,gggggggggggggg ,ggggggggggggggg  _,gggggg,_      ,ggggggggggg,   
dP""Y8,8P"""""Y8b  ,dP""""""Y8bdP""""""88""""""",88"""Y8b,dP"""88""""""Y8,           dP""8IdP""""""88""""""dP""""""88""""""",d8P""d8P"Y8b,   dP"""88""""""Y8, 
Yb, `8dP'     `88  d8'    a  Y8Yb,_    88      d8"     `Y8Yb,  88      `8b          dP   88Yb,_    88      Yb,_    88      ,d8'   Y8   "8b,dPYb,  88      `8b 
 `"  88'       88  88     "Y8P' `""    88     d8'   8b  d8 `"  88      ,8P         dP    88 `""    88       `""    88      d8'    `Ybaaad88P' `"  88      ,8P 
     88        88  `8baaaa             88    ,8I    "Y88P'     88aaaad8P"         ,8'    88     ggg88gggg          88      8P       `""""Y8       88aaaad8P"  
     88        88 ,d8P""""             88    I8'               88""""Yb,          d88888888        88   8          88      8b            d8       88""""Yb,   
     88        88 d8"                  88    d8                88     "8b   __   ,8"     88        88              88      Y8,          ,8P       88     "8b  
     88        88 Y8,            gg,   88    Y8,               88      `8i dP"  ,8P      Y8  gg,   88        gg,   88      `Y8,        ,8P'       88      `8i 
     88        Y8,`Yba,,_____,    "Yb,,8P    `Yba,,_____,      88       Yb,Yb,_,dP       `8b, "Yb,,8P         "Yb,,8P       `Y8b,,__,,d8P'        88       Yb,
     88        `Y8  `"Y8888888      "Y8P'      `"Y8888888      88        Y8 "Y8P"         `Y8   "Y8P'           "Y8P'         `"Y8888P"'          88        Y8
```

### A lightweight Bash tool for extracting structured OSINT data from Netcraft's Site Report — straight from your terminal.

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![jq](https://img.shields.io/badge/jq-required-blue)](https://stedolan.github.io/jq/)
[![Perl](https://img.shields.io/badge/Perl-required-39457E?logo=perl&logoColor=white)](https://www.perl.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## About

**Netcraft Extractor** queries [Netcraft's Site Report](https://sitereport.netcraft.com) — the same public tool available in your browser — via its internal AJAX endpoint, and parses the returned HTML into clean, readable terminal output.

No API key. No browser. No copy-pasting from a webpage. Just a domain and a flag.

Built for quick passive reconnaissance during pentesting engagements (OSINT phase), but works for anyone who wants a faster way to read a Netcraft report.

> **Note:** this tool relies on an undocumented, internal endpoint used by Netcraft's own frontend. It is not an official API, is not affiliated with Netcraft Ltd., and its structure can change without notice.

---

## Features

| Flag | Description |
|---|---|
| `-host <target>` | Site title, rank, description, first seen date, primary language |
| `-dmarc <target>` | DMARC record status and details |
| `-spf <target>` | SPF record status and details |
| `-technology <target>` | Detected technology stack, grouped by category (Cloud & PaaS, Server-Side, Client-Side, etc.) |
| `-webbugs <target>` | Third-party trackers / web bugs found on the site |
| `-all <target>` | Runs every query above in sequence |
| `-keys <target>` | Lists the top-level JSON keys returned by Netcraft (useful if their response format changes) |
| `-raw <target>` | Dumps the full raw JSON response |
| `-o <file>` | Saves output to a file (combine with any flag above) |
| `-h` | Shows the help menu |

---

## Requirements

- `bash`
- `curl`
- [`jq`](https://stedolan.github.io/jq/)
- `perl` (used for HTML parsing — included by default on most Linux distros)

Install missing dependencies on Debian/Kali/Ubuntu:

```bash
sudo apt install jq perl
```

---

## Installation

```bash
git clone https://github.com/xav1ersys/netcraft-extractor.git
cd netcraft-extractor
chmod +x netcraft.sh
```

---

## Usage

```bash
./netcraft.sh -all target.com
```

Run a single query:

```bash
./netcraft.sh -host target.com
./netcraft.sh -technology target.com
```

Save output to a file:

```bash
./netcraft.sh -all target.com -o report.txt
```

Debug Netcraft's response structure:

```bash
./netcraft.sh -keys target.com
./netcraft.sh -raw target.com
```

### Example output

```
== INFORMAÇÕES GERAIS ==
Site title: campsmk
Site rank: Not Present
Description: SEASON 3 - MK: NATIONAL TOURNAMENTS
Date first seen: August 2021
Primary language: Portuguese

== TECNOLOGIAS DETECTADAS ==

-- Cloud & PaaS --
Technology | Description | Popular sites using this technology
Amazon Web Services - EC2 | Cloud computing service (Elastic Compute Cloud) | www.opera.com, ...

-- Tools --
Technology | Description | Popular sites using this technology
Webnode: Online web page generator
```

---

## Known limitations

- **`rowspan` handling:** when a table cell spans multiple rows (e.g. multiple trackers from the same company in `-webbugs`), the label isn't repeated on subsequent rows. The data is still there — just infer it from the row above.
- Field names (`background_table`, `dmarc_table`, etc.) are tied to Netcraft's current internal response format. If they change it, run `-keys` to find the new names.

---

## Disclaimer

This tool only queries **publicly available** information that Netcraft already exposes through its own website — the same data anyone can see by visiting `sitereport.netcraft.com` in a browser. It performs passive reconnaissance only and does not access, exploit, or interact with the target domain itself.

Use responsibly and in accordance with Netcraft's terms of service.

---

## Author

**xav1ersys**
- [github.com/xav1ersys](https://github.com/xav1ersys)

---

## License

[MIT](LICENSE)
