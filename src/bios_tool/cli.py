import argparse

from bios_tool.bios import BiosConfig


def main():
    parser = argparse.ArgumentParser(prog="bios-tool", description="Vendor-agnostic BIOS tooling")
    parser.add_argument('-i', '--ip', type=str, required=True, help='IP address of the target server')
    parser.add_argument('-u', '--username', type=str, required=True, help='Username for the target server')
    parser.add_argument('-p', '--password', type=str, required=True, help='Password for the target server')
    parser.add_argument(
                        '-m', '--manufacturer', type=str, choices=['dell', 'smc'], required=True, 
                        help='Manufacturer of the target server (dell, smc)')
    parser.add_argument('-o', '--outdir', type=str, default='configs', help='Output directory for BIOS config files')
    parser.add_argument('-f', '--format', type=str, choices=['xml', 'json'], default='xml', 
                        help='Format for BIOS config file (xml or json)')
    parser.add_argument('-F', '--file', type=str, help='Path to BIOS settings file for "set" command')
    parser.add_argument('--stage', action='store_true', help='Stage the BIOS settings without applying them')
    parser.add_argument('--version', action='version', version='bios-tool 1.0.0')

    sub = parser.add_subparsers(dest="cmd")
    sub.add_parser("get", help="Export current BIOS config to file")
    sub.add_parser("set", help="Import BIOS config from file")

    args = parser.parse_args()

    bios = BiosConfig(
        ip=args.ip,
        username=args.username,
        password=args.password,
        manufacturer=args.manufacturer
    )

    if args.cmd == "get":
        return bios.get_bios(ext=args.format, outdir=args.outdir)
    elif args.cmd == "set":
        return bios.set_bios(file=args.file, stage=args.stage)

    if args.cmd == "version":
        from . import __version__
        print(__version__)
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
