# Data

The survey data used in this project are **not included in this repository**. They are free from the Federal Reserve, and a reader who downloads the source files and runs our build has reproduced the whole chain.

## Source data

**2025 Survey of Consumer Finances (SCF)**, public data, from the [Federal Reserve SCF page](https://www.federalreserve.gov/econres/scfindex.htm). Download the Stata versions of three files:

| File | What it is |
|---|---|
| `p25i6.dta` | Full public data set |
| `rscfp2025.dta` | Summary extract |
| `p25_rw1.dta` | Replicate weights |

## Expected local files

```text
data/
└── raw/
    ├── p25i6.dta
    ├── rscfp2025.dta
    └── p25_rw1.dta
```

Run the Stata scripts from the repository folder. `code/01_build.do` writes the analysis dataset to `data/derived/`, and `code/02_analyze.do` writes the input file for the Python layer there too. None of these files belongs in version control; `.gitignore` keeps them out.

## Verifying your build

The build stops on its own if the data drift from what we expect. Watch for these values:

- **4,360** families, each appearing five times (one per implicate): **21,800** records
- **1,568** families carrying a credit card balance (implicate 1)
- Weighted shares of a one-month windfall: **22.3%** spend, **47.3%** save, **30.3%** pay down debt (the Federal Reserve reports 22 / 47 / 30)

A successful build ends with `VALIDATION PASSED`.

### Source-file checksums

The SHA-256 values for the exact source files used in the original analysis
were not preserved, so this repository cannot certify that a downloaded file
is byte-for-byte identical to the authors' copy. Record fingerprints for the
files you use with:

```bash
shasum -a 256 data/raw/p25i6.dta data/raw/rscfp2025.dta data/raw/p25_rw1.dta
```

On Linux, use `sha256sum` with the same paths. Include these locally
calculated values when reporting a reproduction; they identify your copies but
are not reference hashes supplied by the authors or the Federal Reserve. In
PowerShell, use `Get-FileHash -Algorithm SHA256` on each file.

## Questions

Open an Issue, or email householdfinancelab@gmail.com.
