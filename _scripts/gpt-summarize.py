import os, re, json, argparse
from bs4 import BeautifulSoup
from dotenv import load_dotenv
load_dotenv()

can_use_gpt = False
try:
    from openai import OpenAI
    api_key = os.getenv("OPENAI_API_KEY")
    fine_tune_gpt_model = os.getenv("FINE_TUNE_GPT_MODEL")
    openai_client = OpenAI(api_key = api_key)
    can_use_gpt = True
except:
    pass

gpt_prompt = "You are a program designed to summarize blog posts in a certain fun tone and style of speech in under 200 characters. Do not use colons, semicolons, or new lines. Please summarize the following blog post:"

def import_markdown(file_path):
    with open(file_path, 'r') as file:
        markdown_text = file.read()
    # print(file_path + " has been imported")
    return markdown_text

def remove_html(markdown):
    soup = BeautifulSoup(markdown, 'html.parser')

    tags_to_remove = ['figure', 'picture', 'p', 'script']
    for tag_type in tags_to_remove:
        tags_of_type = soup.find_all(tag_type)
        for tag in tags_of_type:
            tag.decompose()    
    
    return str(soup)

def convert_md_to_gpt(markdown_text):
    no_tags_markdown_text = remove_html(markdown_text).replace("\n\n\n", "")
    no_yaml_markdown_text = re.sub(r'---.*?---\s*', '', no_tags_markdown_text, flags=re.DOTALL)
    return no_yaml_markdown_text

def extract_description_line(text):
    lines = text.split('\n')
    for line in lines:
        if 'description: ' in line:
            return line.replace('description: ', "")
    return None


def generate_jsonl_training_file():
    global gpt_prompt
    writeup_data = []
    jsonl_export = []
    post_folder = "_posts/"

    for post_filename in os.listdir(post_folder):
        file_text = import_markdown(post_folder + post_filename)
        if ".md" in post_filename and "description: " in file_text:
            writeup_data.append( [convert_md_to_gpt(file_text), extract_description_line(file_text)] )
            
    for post_data in writeup_data:
        entry = {
            "messages": [
                {"role": "system","content": f"{gpt_prompt}"},
                {"role": "user","content": post_data[0]},
                {"role": "assistant","content": post_data[1]}
            ]
        }
        jsonl_export.append(entry)
    
    with open('_scripts/description-data.jsonl', 'w') as f:
        for item in jsonl_export:
            f.write(json.dumps(item) + "\n")

            
def check_posts_for_no_desc():
    post_folder = "_posts/"
    generated_descriptions = []
    for post_filename in os.listdir(post_folder):
        post_filepath = post_folder + post_filename
        file_text = import_markdown(post_filepath)
        if ".md" in post_filename and not has_valid_description(file_text):
            print(f"Generating description for {post_filename}")
            gpt_generated_description = get_fine_tune_responce(convert_md_to_gpt(file_text))
            generated_descriptions.append(gpt_generated_description)
            updated_post_text = add_description_to_post(file_text, gpt_generated_description)
            update_post_file(post_filepath, updated_post_text)
    if len(generated_descriptions) == 0:
        print("No descriptions were generated.")
        return
    print("Generated Descriptions:")
    for desc in generated_descriptions:
        print(f"  - {desc}")

def has_valid_description(file_text):
    if not "description: " in file_text:
        return False
    # get the line with the description without using the function
    description_line = ""
    for line in file_text.split('\n'):
        if 'description:' in line:
            description_line = line.replace('description:', "").replace(' ', "")
            break
    if len(description_line) < 2:
        return False
    return True

def add_description_to_post(text, description_to_add):
    if 'description:' in text:
        return text.replace('description:', 'description: ' + description_to_add)
    old = '---'
    new = 'description: ' + description_to_add + '\n---'
    offset = text.index(old) + 1
    a = text[:offset] + text[offset:].replace(old, new, 1)
    return a

def update_post_file(filepath, file_data):
    with open(filepath, 'w') as f:
        f.write(file_data)


def get_fine_tune_responce(post_text):
    global gpt_prompt, openai_client, fine_tune_gpt_model
    response = openai_client.chat.completions.create(
      model=fine_tune_gpt_model,
      messages=[
        {"role": "system","content": f"{gpt_prompt}"},
        {"role": "user","content": post_text}
      ]
    )
    return(response.choices[0].message.content)

def main():
    global can_use_gpt
    parser = argparse.ArgumentParser(description="GPT Summarization Script for Blog Posts")
    parser.add_argument('--generate-descriptions', action='store_true', help="Generate descriptions for posts without them")
    parser.add_argument('--generate-jsonl', action='store_true', help="Generate a jsonl file for fine tuning")
    
    args = parser.parse_args()
    
    if args.generate_jsonl:
        generate_jsonl_training_file()
    elif args.generate_descriptions:
        if can_use_gpt:
            check_posts_for_no_desc()
        else:
            print("Please set the OPENAI_API_KEY environment variable.")
            exit(1)
    else:
        print("No valid argument provided. Use --generate-descriptions or --generate-jsonl")

if __name__ == "__main__":
    main()