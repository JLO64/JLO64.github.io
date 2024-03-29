import base64, os, sys, re
from dotenv import load_dotenv

load_dotenv()

from imagekitio import ImageKit
from imagekitio.models.UploadFileRequestOptions import UploadFileRequestOptions
imagekit = ImageKit(
    private_key = os.getenv('imagekit_private_key'),
    public_key = os.getenv('imagekit_public_key'),
    url_endpoint = os.getenv('imagekit_url_endpoint')
)

def import_markdown(file_path):
    with open(file_path, 'r') as file:
        markdown_text = file.read()
    print(file_path + " has been imported")
    return markdown_text

def overwrite_file_with_markdown(file_path, markdown_text):
    with open(file_path, 'w') as file:
        file.write(markdown_text)
    print(file_path + " has been updated")

def get_image_paths_from_markdown_file(markdown_text):
    pattern_one = r'\!\[.*?\]\((.*?)\)'
    pattern_two = r'url="(.*?)"'
    matches_one = re.findall(pattern_one, markdown_text)
    matches_two = re.findall(pattern_two, markdown_text)
    matches_one.extend(matches_two)
    matches = [match for match in matches_one if 'images' in match and 'ik.imagekit.io' not in match]
    return matches

def upload_image(filename, imagekit_foldername):
    options = UploadFileRequestOptions(
        folder=imagekit_foldername
    )
    
    print(" Uploading " + filename)
    upload = imagekit.upload(
        file=open("images/" + filename.replace("/images/", "").replace("images/", ""), "rb"),
        file_name=filename,
        options=options
    )
    print(" " + filename + " was uploaded")
    print(" " + filename + "'s url is: '" + str(upload.url))

    #print(upload.response_metadata.raw)

    return str(upload.url)

post_folder = "_posts/"

for post_filename in os.listdir(post_folder):
    markdown_text = import_markdown(post_folder + post_filename)

    blog_image_filepaths = get_image_paths_from_markdown_file(markdown_text)
    if len(blog_image_filepaths) > 0:
        print( " " + str(len(blog_image_filepaths)) + " images to process found")
        for image_filepath in blog_image_filepaths:
            image_filename = image_filepath.replace("../images/", "").replace("/images", "")
            image_url = upload_image(filename=image_filename, imagekit_foldername="/www_julianlopez_net/" + post_filename.replace(".md","") + "/")
            markdown_text = markdown_text.replace(image_filepath, image_url)
            os.remove(image_filepath.replace("../", "").replace("/images", "images"))
            print(" " + image_filepath + " has been deleted")
        overwrite_file_with_markdown(post_folder + post_filename, markdown_text)
    else:
        print(" No images to process found")