#!/usr/bin/env python3
import sys
import os
from PIL import Image
import numpy as np

def remove_white_bg(input_path, output_path=None, tolerance=15):
    if output_path is None:
        output_path = input_path

    try:
        img = Image.open(input_path).convert('RGBA')
        data = np.array(img)
        
        r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
        
        # Detect white background
        is_white = (r >= 255 - tolerance) & (g >= 255 - tolerance) & (b >= 255 - tolerance)
        
        # Make transparent
        data[is_white, 3] = 0
        
        result = Image.fromarray(data)
        result.save(output_path, 'PNG')
        
        h, w = data.shape[:2]
        changed = np.sum(is_white)
        percentage = changed / (h * w) * 100
        
        print(f"Processed: {input_path}")
        print(f"  - Output: {output_path}")
        print(f"  - Pixels removed: {changed:,} ({percentage:.1f}%)")
        return True
    except Exception as e:
        print(f"Error processing {input_path}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 remove_white_bg.py <image_path> [output_path]")
        sys.exit(1)
        
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file
    
    remove_white_bg(input_file, output_file)
