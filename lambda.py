import base64
import boto3
import json
import random
import string
import time


def store(env):
    if env['body']['full_url'] is None or env['body']['full_url'] == '':
        return {}
    dynamo = boto3.client('dynamodb', region_name='us-east-1')
    while True:
        try:
            short_url_id = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(6))
            dynamo.put_item(
                TableName='URLDB',
                Item={
                    'short_url_id': {'S': short_url_id},
                    'full_url': {'S': env['body']['full_url']},
                    'created_at': {'N': str(int(time.time()))},
                    'ttl': {'N': str(int(time.time()) + (86400 * 30))}
                },
                ConditionExpression='attribute_not_exists(short_url_id)'
            )
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'short_url_id': short_url_id})
            }
        except dynamo.exceptions.ConditionalCheckFailedException:
            pass


def redirect(env):
    short_url_id = env['path'].split('/')[-1]
    dynamo = boto3.client('dynamodb', region_name='us-east-1')
    response = dynamo.get_item(
        TableName='URLDB',
        Key={'short_url_id': {'S': short_url_id}},
        AttributesToGet=['full_url'],
    )
    if response['Item']['full_url']['S'] is None:
        return {'statusCode': 404, 'headers': {}, 'body': ''}
    else:
        return {'statusCode': 302, 'headers': {'Location': response['Item']['full_url']['S']}, 'body': ''}


def router(env):
    if env['path'] == '/store' and env['method'] == 'POST':
        return store(env)
    elif env['method'] == 'GET':
        return redirect(env)
    else:
        return {'statusCode': 404, 'headers': {}, 'body': ''}


def handler(event, context):
    if event['body'] is None:
        body = None
    elif event['isBase64Encoded']:
        body = json.loads(base64.b64decode(event['body']))
    else:
        body = json.loads(event['body'])

    env = {
        'method': event['requestContext']['httpMethod'],
        'path': event['requestContext']['path'],
        'params': event['queryStringParameters'] if event['queryStringParameters'] is not None else '',
        'body': body
    }

    resp = router(env)
    resp['isBase64Encoded'] = False
    return resp
