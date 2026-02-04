#!/usr/bin/env python3
"""
Script to remove checkered transparency pattern from PNG and convert to real transparency.
The checkered pattern typically consists of alternating gray pixels.
"""

from PIL import Image
import numpy as np

def remove_checkered_pattern(input_path, output_path):
    # Load image
    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)
    
    # The checkered pattern typically uses these colors:
    # Light gray: around (192, 192, 192) or (204, 204, 204)
    # Dark gray: around (128, 128, 128) or (153, 153, 153)
    
    # Create mask for pixels that are gray (part of the checkered pattern)
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    
    # Detect gray pixels where R ≈ G ≈ B (within tolerance)
    # and the values are in the typical checkered range (100-220)
    tolerance = 15
    is_gray = (np.abs(r.astype(int) - g.astype(int)) < tolerance) & \
              (np.abs(g.astype(int) - b.astype(int)) < tolerance) & \
              (np.abs(r.astype(int) - b.astype(int)) < tolerance)
    
    # Check if it's in the typical checkered gray range
    is_checkered_gray = is_gray & (r > 100) & (r < 220)
    
    # Make these pixels transparent
    data[is_checkered_gray, 3] = 0  # Set alpha to 0
    
    # Save result
    result = Image.fromarray(data)
    result.save(output_path, 'PNG')
    print(f"Saved: {output_path}")
    
    # Count pixels changed
    changed = np.sum(is_checkered_gray)
    total = data.shape[0] * data.shape[1]
    print(f"Made {changed:,} pixels transparent ({changed/total*100:.1f}% of image)")

if __name__ == '__main__':
    remove_checkered_pattern(
        'assets/mepriga_logo.png',
        'assets/mepriga_logo_fixed.png'
    )
