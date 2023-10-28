# asahi-overlay

Asahi Linux specific Gentoo Overlay for M* Macs

## Usage

We recommend using `app-eselect/eselect-repository`: `emerge --ask app-eselect/eselect-repository`

```bash
eselect repository add asahi-overlay git https://github.com/jaredallard/asahi-overlay.git
```

Otherwise, if using `layman`:

```bash
layman -o https://raw.githubusercontent.com/jaredallard/asahi-overlay/main/repositories.xml -f -a asahi-overlay
```

## License

GPL-2.0
