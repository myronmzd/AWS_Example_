import json
import random

def lambda_handler(event, context):
    quotes = [
        "The best way to predict the future is to invent it. – Alan Kay",
        "Do one thing every day that scares you. – Eleanor Roosevelt",
        "Success is not the key to happiness. Happiness is the key to success. – Albert Schweitzer",
        "Dream big and dare to fail. – Norman Vaughan",
        "Life is 10% what happens to us and 90% how we react to it. – Charles R. Swindoll"
    ]

    # Pick a random quote
    selected_quote = random.choice(quotes)

    # Response
    response = {
        "statusCode": 200,
        "body": json.dumps({"quote": selected_quote})
    }

    return response
## test 

# {
#   "quote": "Do one thing every day that scares you. – Eleanor Roosevelt"
# }

