# 0x02 - Forensic Methodologies

## Task 0: The Case of the Mysterious Image

### Objective
Analyze an image file using digital forensics tools to extract hidden metadata and identify the owner name.

### Tools Used
- **exiftool** – a powerful command-line utility for reading, writing, and editing metadata in a wide variety of file types.

### Methodology
1. Downloaded the provided image file.
2. Ran `exiftool` to extract all metadata:
   ```bash
   exiftool mystery_image.jpg
