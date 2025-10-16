import subprocess
import os
import shlex

from bios_tool.utils import is_command, is_dir_writeable
from bios_tool.racadm import Racadm


class BiosConfig:
    """
    This class represents a BiosConfig, which is responsible for configuring the BIOS settings of a server.

    Functions:
    - get_bios(ext, outdir): Retrieves the BIOS settings of the server and saves them to a file in the specified output directory.
    - set_bios(file=None, stage=False): Sets the BIOS settings of the server.  If a file is specified it will be used otherwise one
    will be automatically determined and pulled from the hardware-config-files repo in s3.

    Sample Usage:
    bios = BiosConfig(ip, username, password, manufacturer)
    bios.get_bios('xml', '/tmp')
    bios.set_bios(file='bios_settings.xml', stage=True)
    """

    def __init__(self, ip: str, username: str, password: str, manufacturer: str):
        self.ip = ip
        self.username = username
        self.password = password
        self.manufacturer = manufacturer.lower()

        if self.manufacturer == "dell":
            self.racadm = Racadm(ip=self.ip, username=self.username, password=self.password)


    def _extract_jid(self, output: str) -> str:
        jid_start = output.find("JID_")
        jid_end = output.find('"', jid_start)

        jid = output[jid_start:jid_end]

        return jid
    

    def _get_dell(self, outdir: str, ext: str = "xml") -> str:
        """
        This function uses racadm to export the current bios config from the given machine.

        Expected input:
        ext = xml OR json
        outdir = Directory to save exported file to.

        The output will be a path to the downloaded file.
        """
        outfile = f"{outdir}/{self.ip}.{ext}"
        outfile = shlex.quote(outfile)
        args = [
            "-f",
            outfile,
            "-t",
            ext,
        ]

        result = self.racadm.get(endpoint=None, arguments=args)

        if "file exported successfully" in result:
            return outfile
        else:
            print(f"Failed to get bios file for {self.ip}")
            raise RuntimeError(result)


    def _get_smc(self, outdir: str) -> str:
        """
        This function uses sum to export the current bios config from the given machine.

        Expected input:
        outdir = Directory to save exported file to.

        The output will be a paath to the downloaded file.
        """
        sum = "/usr/local/bin/sum"
        outfile = f"{outdir}/{self.ip}.xml"
        outfile = shlex.quote(outfile)
        is_command(sum)
        command = [
            sum,
            "-i",
            self.ip,
            "-u",
            self.username,
            "-p",
            self.password,
            "-c",
            "GetCurrentBiosCfg",
            "--file",
            outfile,
        ]

        result = subprocess.run(command, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stderr = result.stderr

        if result.returncode == 0:
            if os.path.getsize(outfile) > 0:
                return outfile
            else:
                print("Failed to get bios file for {id}")
                raise RuntimeError(stderr)
        else:   
            print("Failed to get bios file for {id}")
            raise RuntimeError(stderr)
        

    def _set_dell(self, file: str) -> dict:
        """
        This function uses racadm to apply a given bios config to a given dell server.

        Expected input:
        file = the bios config file to be applied.  Can be xml or json

        This function will return true if success or raise an exception if failure.
        """
        ext = file.rsplit(".", 1)[-1]
        ext = shlex.quote(ext)
        args = ["-b", "Forced", "-f", file, "-t", ext, "-s", "Off"]
        out_obj = {}

        result = self.racadm.set(endpoint=None, arguments=args)

        if "File transferred successfully" in result:
            jid = self._extract_jid(result)
            wait = self.racadm.jobqueue_wait(jid).lower()
            out_obj.update({"status": wait})
            out_obj.update({"jid": jid})
            return out_obj
        else:
            print("Failed to set bios for {id}")
            raise RuntimeError(result)
    

    def _set_smc(self, file: str, stage: bool = False) -> dict:
        """
        This function uses sum to apply a given bios config to a given smc server.  If stage=True the config
        will only be staged and the server will need to be rebooted manually to complete the operation.

        Expected input:
        file = the bios config file to be applied.  Can be xml or json
        stage = boolean

        This function will return true if success or raise an exception if failure.
        """
        sum = "/usr/local/bin/sum"
        is_command(sum)
        command = [
            sum,
            "-i",
            self.ip,
            "-u",
            self.username,
            "-p",
            self.password,
            "-c",
            "ChangeBiosCfg",
            "--skip_unknown",
            "--file",
            file,
        ]
        out_obj = {}

        if not stage:
            command += ["--reboot"]

        result = subprocess.run(command, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stderr = result.stderr

        if result.returncode == 0:
            stdout = result.stdout
            if "The BIOS configuration is updated" in stdout:
                out_obj.update({"status": "completed"})
                return out_obj
            else:
                print("Failed to set bios for {id}")
                raise RuntimeError(stderr)
        else:
            print("Failed to set bios for {id}")
            raise RuntimeError(stderr)


    def get_bios(self, ext, outdir=None):
        if outdir == None:
            outdir = "/tmp"
        is_dir_writeable(outdir)

        if self.manufacturer == 'dell':
            return self._get_dell(outdir, ext)
        elif self.manufacturer == 'smc':
            if ext != "xml":
                print("Currently SMC supports only xml")
            return self._get_smc(outdir)
        else:
            raise RuntimeError(f"Manufacturer ({self.manufacturer_id}): currently not supported")


    def set_bios(self, file=None, stage=False):
        # Require a file argument and ensure it exists on the filesystem.
        if not file:
            raise FileNotFoundError("No BIOS file provided to set_bios")

        if not os.path.exists(file):
            raise FileNotFoundError(f"BIOS file not found: {file}")

        # Dispatch based on the normalized manufacturer set on the instance.
        if self.manufacturer == "dell":
            return self._set_dell(file)
        elif self.manufacturer == "smc":
            # use the top-level helper for Supermicro SUM
            return self._set_smc(file, stage)
        else:
            raise RuntimeError(f"Manufacturer ({self.manufacturer}): currently not supported")
