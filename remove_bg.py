from PIL import Image
import os
import glob

def make_transparent(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()
    
    new_data = []
    # Convert black to transparent, preserving color for bright pixels mapped to alpha
    for item in datas:
        r, g, b, a = item
        # Calculate luma
        luma = (r * 0.299 + g * 0.587 + b * 0.114)
        
        # If it's pure black or very dark, lower the alpha
        if luma < 10:
            new_data.append((r, g, b, 0))
        elif luma < 100:
            # Smooth transition for anti-aliasing
            alpha = int(((luma - 10) / 90) * 255)
            new_data.append((r, g, b, alpha))
        else:
            new_data.append((r, g, b, 255))
            
    img.putdata(new_data)
    img.save(output_path, "PNG")

if __name__ == "__main__":
    images = glob.glob("../attendance-dashboard/public/3d/*.png")
    for img_path in images:
        print(f"Processing {img_path}...")
        make_transparent(img_path, img_path)
