import shutil
import os

class DirectoryError(Exception):
    """
    Custom exception to throw directoryerror
    """

    pass

def is_command(cmd: str) -> bool:
    """
    is_command(cmd: str)
        Checks if a given command is in the PATH on the current system.
    """
    if shutil.which(cmd) is not None:
        return True
    else:
        raise FileNotFoundError(
            f"The command '{cmd}' was not found.  Please ensure this is run from the platops-toolbox"
        )

def is_dir_writeable(dir: str) -> bool:
    """
    Function to test whether or not a directory exists and is writeable.

    Sample Usage:
    if is_dir_writeable(dir):
        do_thing()
    """
    if os.path.exists(dir):
        if os.access(dir, os.W_OK):
            return True
        else:
            raise DirectoryError(f"The directory '{dir}' is not writeable")
    else:
        raise DirectoryError(f"The directory '{dir}' does not exist")