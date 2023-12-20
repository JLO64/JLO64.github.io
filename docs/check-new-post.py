import requests, os, re, time
from bs4 import BeautifulSoup
import xml.etree.ElementTree as ET
from dotenv import load_dotenv

load_dotenv()

from mastodon import Mastodon
mastodon = Mastodon(
    access_token=os.getenv('mastodon_access_token'),
    api_base_url='https://fosstodon.org'
)

def extract_posts(root):
    posts = []
    for child in root:
        if '/posts/' in child[0].text and len(child[0].text) > 39:
            posts.append(child[0].text)
    return posts

def get_posts_from_url_sitemap(sitemap_url):
    response = requests.get(sitemap_url)
    root = ET.fromstring(response.content)
    return extract_posts(root)

def get_posts_from_local_sitemap(filepath):
    with open(filepath, 'r') as f:
        root = ET.fromstring(f.read())
    return extract_posts(root)

def compare_sitemaps(sitemap_url, filepath):
    sitemap1 = get_posts_from_url_sitemap(sitemap_url)
    sitemap2 = get_posts_from_local_sitemap(filepath)
    unique_sitemap2 = set(sitemap2) - set(sitemap1)
    return unique_sitemap2

def extract_h1_tag(html_file):
    with open(html_file, 'r') as f:
        html_content = f.read()
    h1_regex = r'<h1 class="post-title">(.*?)</h1>'
    match = re.search(h1_regex, html_content)
    return match.group(1)

def extract_tags(html_file):
    with open(html_file, 'r') as f:
        html_content = f.read()
    soup = BeautifulSoup(html_content, 'html.parser')
    tags = soup.find_all('span', class_='tag')
    return [tag.a.text for tag in tags if tag.a]

def post_blog_to_mastodon(title, url, tags):
    print("Posting to Mastodon")
    post_text = title + ": " + url + "\n#"
    post_text += ' #'.join(tags)
    time.sleep(180)
    mastodon.status_post(post_text)
    print(post_text)

def main():
    new_posts = compare_sitemaps('https://www.julianlopez.net/sitemap.xml', 'docs/sitemap.xml')
    if len(new_posts) == 0:
        print('No new posts found.')
        return
    for new_post_url in new_posts:
        new_post_html_loc =  "docs/"+  new_post_url.replace("https://www.julianlopez.net/", "") + ".html"
        post_title = extract_h1_tag(new_post_html_loc)
        post_tags = extract_tags(new_post_html_loc)
        post_blog_to_mastodon(post_title, new_post_url, post_tags)

main()