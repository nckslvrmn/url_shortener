import boto3
import json
import random
import re
import string
import time

def store(env):
    if env['body']['full_url'] == None or env['body']['full_url'] == '':
        return {}
    short_url_id = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(16))
    dynamo = boto3.client('dynamodb', region_name = 'us-east-1')
    response = dynamo.put_item(
        TableName = 'URLDB',
        Item = {
            'short_url_id': {
                'S': short_url_id
            },
            'full_url': {
                'S': env['body']['full_url']
            },
            'created_at': {
                'N': str(int(time.time()))
            },
            'ttl': {
                'N': str(int(time.time()) + (86400 * 30))
            }
        }
    )
    return {
        'statusCode': 200,
        'headers': { 'Content-Type': 'application/json' },
        'body': json.dumps({ 'short_url_id': short_url_id })
    }

def redirect(env):
    short_url_id = env['path'].split('/')[-1]
    dynamo = boto3.client('dynamodb', region_name = 'us-east-1')
    response = dynamo.get_item(
        TableName = 'URLDB',
        Key = { 'short_url_id': { 'S': short_url_id } },
        AttributesToGet = ['full_url'],
    )
    if response['Item']['full_url']['S'] == None:
        return { 'statusCode': 404, 'headers': {}, 'body': '' }
    else:
        return { 'statusCode': 302, 'headers': { 'Location': response['Item']['full_url']['S'] }, 'body': '' }

def router(env):
    p = re.compile(r'/r/+')
    if env['path'] == '/store' and env['method'] == 'POST':
        return store(env)
    elif p.match(env['path']) and env['method'] == 'GET':
        return redirect(env)
    else:
        return { 'statusCode': 404, 'headers': {}, 'body': '' }

def handler(event, context):
    if event['body'] == None:
        body = None
    elif event['isBase64Encoded']:
        body = json.loads(base64.b64decode(event['body']))
    else:
        body = json.loads(event['body'])

    env = {
        'method': event['requestContext']['httpMethod'],
        'path': event['requestContext']['path'],
        'params': event['queryStringParameters'] if event['queryStringParameters'] != None else '',
        'body': body
    }

    resp = router(env)
    resp['isBase64Encoded'] = False
    return resp
