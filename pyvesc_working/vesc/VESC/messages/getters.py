class GetFirmwareVersion:
    id = 1
    fw_major = 0
    fw_minor = 0
    fw_patch = 0
    def __str__(self):
        return f"{self.fw_major}.{self.fw_minor}.{self.fw_patch}"
