# overlay

A general purpose overlay maintained by Outreach.

## Usage

We recommend using `app-eselect/eselect-repository`: `emerge --ask app-eselect/eselect-repository`

```bash
eselect repository add outreach git https://github.com/getoutreach/overlay.git
```

Otherwise, if using `layman`:

```bash
layman -o https://raw.githubusercontent.com/getoutreach/overlay/main/repositories.xml -f -a outreach
```

## License

GPL-2.0
