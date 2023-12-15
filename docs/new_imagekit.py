import os
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

from imagekitio import ImageKit
from imagekitio.models.UploadFileRequestOptions import UploadFileRequestOptions
imagekit = ImageKit(
    private_key = os.getenv('imagekit_private_key'),
    public_key = os.getenv('imagekit_public_key'),
    url_endpoint = os.getenv('imagekit_url_endpoint')
)

def write_url_to_file(image_url):
    with open('images/pictures-html.md', 'a') as file:
        file.write('\n<picture>\n')
        file.write('    <source srcset="' + image_url + '?tr=w-720,f-webp," type="image/webp">\n')
        file.write('    <img src="' + image_url + '?tr=w-480" alt="ALT TEXT HERE" class="blog_image" title="ALT TEXT HERE">\n')
        file.write('    <figcaption style="text-align:center"> CAPTION TEXT HERE </figcaption>\n')
        file.write('<picture>\n')


def upload_image(filename, imagekit_foldername):
    options = UploadFileRequestOptions(
        folder=imagekit_foldername
    )
    
    print(" Uploading " + filename)
    upload = imagekit.upload(
        file=open("images/" + filename.replace("/images/", "").replace("images/", ""), "rb"),
        file_name=os.path.splitext(filename)[0] + "-" + str(datetime.now().strftime('%Y-%m-%d')),
        options=options
    )
    print(" " + filename + " was uploaded")
    print(" " + filename + "'s url is: '" + str(upload.url))

    #print(upload.response_metadata.raw)

    return str(upload.url)

def main():
    image_folder = "images/"

    for image_filename in os.listdir(image_folder):
        if " " in image_filename:
            print("Within the filename of'" + image_filename + "' there are spaces. Aborting upload sequence.")
            return
        elif ".md" in image_filename: pass
        elif image_filename[0] == ".": pass
        else:
            image_url = upload_image(filename=image_filename, imagekit_foldername="/www_julianlopez_net/")
            write_url_to_file(image_url)
            os.remove( "images/" + image_filename.replace("../", ""))
            print(" " + image_filename + " has been deleted")

main()