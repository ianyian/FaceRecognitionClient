#!/usr/bin/env python3
"""
Generate Face Attendance App Icon
Creates a 1024x1024 PNG with gradient background and camera emoji
"""

from PIL import Image, ImageDraw, ImageFont
import os


def create_gradient(width, height, color1, color2):
    """Create a linear gradient from color1 to color2"""
    base = Image.new('RGB', (width, height), color1)
    top = Image.new('RGB', (width, height), color2)
    mask = Image.new('L', (width, height))
    mask_data = []
    for y in range(height):
        mask_data.extend([int(255 * (y / height))] * width)
    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base


def create_app_icon():
    """Create the app icon"""
    size = 1024

    # iOS Blue gradient (#007AFF to #5856D6)
    color1 = (0, 122, 255)      # iOS Blue
    color2 = (88, 86, 214)      # iOS Purple

    # Create gradient background
    print("Creating gradient background...")
    img = create_gradient(size, size, color1, color2)
    draw = ImageDraw.Draw(img)

    # Add a white circle in the center for camera icon effect
    center = size // 2
    circle_radius = size // 3

    print("Drawing camera lens circle...")
    # Outer circle (camera lens)
    draw.ellipse(
        [center - circle_radius, center - circle_radius,
         center + circle_radius, center + circle_radius],
        fill=(255, 255, 255, 230),
        outline=(240, 240, 240)
    )

    # Inner circle (camera aperture)
    inner_radius = circle_radius // 2
    draw.ellipse(
        [center - inner_radius, center - inner_radius,
         center + inner_radius, center + inner_radius],
        fill=None,
        outline=(0, 122, 255),
        width=20
    )

    # Add camera viewfinder corners
    corner_size = 60
    corner_width = 15
    corner_offset = circle_radius + 80

    print("Adding camera viewfinder corners...")
    # Top-left corner
    draw.line([(center - corner_offset, center - corner_offset),
               (center - corner_offset + corner_size, center - corner_offset)],
              fill=(255, 255, 255), width=corner_width)
    draw.line([(center - corner_offset, center - corner_offset),
               (center - corner_offset, center - corner_offset + corner_size)],
              fill=(255, 255, 255), width=corner_width)

    # Top-right corner
    draw.line([(center + corner_offset, center - corner_offset),
               (center + corner_offset - corner_size, center - corner_offset)],
              fill=(255, 255, 255), width=corner_width)
    draw.line([(center + corner_offset, center - corner_offset),
               (center + corner_offset, center - corner_offset + corner_size)],
              fill=(255, 255, 255), width=corner_width)

    # Bottom-left corner
    draw.line([(center - corner_offset, center + corner_offset),
               (center - corner_offset + corner_size, center + corner_offset)],
              fill=(255, 255, 255), width=corner_width)
    draw.line([(center - corner_offset, center + corner_offset),
               (center - corner_offset, center + corner_offset - corner_size)],
              fill=(255, 255, 255), width=corner_width)

    # Bottom-right corner
    draw.line([(center + corner_offset, center + corner_offset),
               (center + corner_offset - corner_size, center + corner_offset)],
              fill=(255, 255, 255), width=corner_width)
    draw.line([(center + corner_offset, center + corner_offset),
               (center + corner_offset, center + corner_offset - corner_size)],
              fill=(255, 255, 255), width=corner_width)

    # Save the icon
    output_path = 'FaceRecognitionClient/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
    print(f"Saving icon to {output_path}...")
    img.save(output_path, 'PNG', quality=100)
    print(f"✅ App icon created successfully!")
    print(f"   Size: {size}x{size}")
    print(f"   Location: {output_path}")
    print("\nNext steps:")
    print("1. Open Xcode and verify the icon appears")
    print("2. Build the app to see it on simulator/device")
    print("3. Optionally upload to https://appicon.co to generate all sizes")


if __name__ == "__main__":
    try:
        create_app_icon()
    except ImportError as e:
        print("❌ Error: PIL (Pillow) not installed")
        print("\nTo install, run:")
        print("  pip3 install Pillow")
        print("\nOr if using conda:")
        print("  conda install pillow")
    except Exception as e:
        print(f"❌ Error creating icon: {e}")
        import traceback
        traceback.print_exc()
