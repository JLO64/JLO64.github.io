import os
import mailchimp_transactional as MailchimpTransactional
from mailchimp_transactional.api_client import ApiClientError
from dotenv import load_dotenv

load_dotenv()

def run():
  try:
    mailchimp = MailchimpTransactional.Client(os.getenv('mailchimp_api_key'))
    response = mailchimp.users.ping()
    print('API called successfully: {}'.format(response))
  except ApiClientError as error:
    print('An exception occurred: {}'.format(error.text))

run()