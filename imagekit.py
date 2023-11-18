import base64, os, sys, re

from imagekitio import ImageKit
from imagekitio.models.UploadFileRequestOptions import UploadFileRequestOptions
imagekit = ImageKit(
    private_key='private_4h7ssF7ToH26QSTMu4k+LQxQ22Q=',
    public_key='public_IBT2z34MhhVI7KfK6wSL7sebLjY=',
    url_endpoint='https://ik.imagekit.io/jlo64'
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
    pattern = r'\!\[.*?\]\((.*?)\)'
    matches = re.findall(pattern, markdown_text)
    return matches

def upload_image(filename, imagekit_foldername):
    options = UploadFileRequestOptions(
        folder=imagekit_foldername
    )
    
    print("Uploading " + filename)
    upload = imagekit.upload(
        file=open("images/" + filename, "rb"),
        file_name=filename,
        options=options
    )
    print(filename + " was uploaded")
    print(filename + "'s url is: '" + str(upload.url))

    #print(upload.response_metadata.raw)

    return str(upload.url)

post_folder = "_posts/"
post_filename = "2023-11-16-setting-up-my-domain.md"

markdown_text = import_markdown(post_folder + post_filename)

blog_image_filepaths = get_image_paths_from_markdown_file(markdown_text)
if len(blog_image_filepaths) > 0:
    print(len(blog_image_filepaths) + " images to process found")
    for image_filepath in blog_image_filepaths:
        image_filename = image_filepath.replace("../images/", "")
        image_url = upload_image(filename=image_filename, imagekit_foldername="/www_julianlopez_net/" + post_filename.replace(".md","") + "/")
        markdown_text = markdown_text.replace(image_filepath, image_url)
else:
    print("No images to process found")

overwrite_file_with_markdown(post_folder + post_filename, markdown_text)