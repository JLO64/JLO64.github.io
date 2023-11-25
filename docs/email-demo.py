import os
from dotenv import load_dotenv
from mailchimp_marketing import Client

load_dotenv()

mailchimp = Client()
mailchimp.set_config({
  "api_key": os.getenv('mailchimp_marketing_api_key'),
  "server": os.getenv('mailchimp_marketing_server_prefix')
})

response = mailchimp.ping.get()
print(response)


