from PIL import Image, ImageDraw, ImageFont

# Create a new image with black background
img = Image.new('RGB', (1200, 630), color = 'black')

# Load the fonts (adjust the paths and sizes as needed)
font1 = ImageFont.truetype('Ubuntu-Regular.ttf', 50)
font2 = ImageFont.truetype('Ubuntu-BoldItalic.ttf', 100)

d = ImageDraw.Draw(img)

# Convert hex color to RGB
color = (115, 193, 252)

# Add text to the image
d.text((70,50), "Julian Lopez Presents", font=font1, fill=color)
d.text((img.width//2, img.height//2), "Domain of a Knight", font=font2, fill=color, anchor='mm')

# Save the image
img.save('output.png')
