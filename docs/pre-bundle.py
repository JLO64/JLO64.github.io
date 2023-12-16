import base64, os, sys, re, openai
from dotenv import load_dotenv

load_dotenv()


def import_markdown(file_path):
    with open(file_path, 'r') as file:
        markdown_text = file.read()
    print(file_path + " has been imported")
    return markdown_text

def overwrite_file_with_markdown(file_path, markdown_text):
    with open(file_path, 'w') as file:
        file.write(markdown_text)
    print(file_path + " has been updated")

def replace_post_md_links(text):
    def repl(match):
        link = match.group(2)
        if ('/' not in link) and ('#' not in link):
            return f'{match.group(1)}({{% post_url {link} %}})'
        return match.group(0)

    return re.sub(r'(\[.*?\])\((.*?)\)', repl, text)

def main():
    post_folder = "_posts/"

    for post_filename in os.listdir(post_folder):
        if " " in post_filename:
            print("Within the filename of'" + post_filename + "' there are spaces. Aborting preupload sequence.")
            return
        markdown_text = import_markdown(post_folder + post_filename)

        # overwrite_file_with_markdown(post_folder + post_filename, replace_post_md_links(markdown_text))

main()