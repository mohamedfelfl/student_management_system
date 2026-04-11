from rembg import remove
from PIL import Image
import os

input_path = "assets/images/logo.png"
output_path = "assets/images/logo.png" # we can just overwrite, but maybe better to keep a backup? We'll overwrite directly.

print(f"Opening {input_path}...")
try:
    input_image = Image.open(input_path)
    print("Removing background...")
    output_image = remove(input_image)
    print("Saving...")
    output_image.save(output_path)
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
