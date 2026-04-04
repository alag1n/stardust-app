import base64
import urllib.request
import json
import os

GITHUB_OWNER = 'alag1n'
GITHUB_REPO = 'stardust-images'
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN', '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')

CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
}

def handler(event, context):
    method = event.get('httpMethod', 'GET')
    
    # Handle CORS preflight
    if method == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': ''}
    
    # POST - загрузка на GitHub
    if method == 'POST':
        try:
            body = event.get('body', '')
            
            # Parse JSON
            try:
                data = json.loads(body)
                if 'data' in data:
                    file_data = base64.b64decode(data['data'])
                else:
                    file_data = base64.b64decode(body)
            except:
                file_data = base64.b64decode(body)
            
            params = event.get('queryStringParameters', {})
            filename = params.get('filename', 'upload.jpg')
            
            # Upload to GitHub
            url = f'https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/contents/photos/{filename}'
            
            content_b64 = base64.b64encode(file_data).decode('utf-8')
            
            req = urllib.request.Request(
                url,
                data=json.dumps({
                    'message': f'Upload {filename}',
                    'content': content_b64
                }).encode('utf-8'),
                method='PUT',
                headers={
                    'Authorization': f'token {GITHUB_TOKEN}',
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json'
                }
            )
            
            with urllib.request.urlopen(req, timeout=30) as response:
                result = json.loads(response.read().decode('utf-8'))
                image_url = result['content']['download_url']
            
            return {
                'statusCode': 200,
                'headers': CORS_HEADERS,
                'body': json.dumps({'url': image_url})
            }
        except Exception as e:
            return {
                'statusCode': 500,
                'headers': CORS_HEADERS,
                'body': json.dumps({'error': str(e)})
            }
    
    # GET - чтение
    url = event.get('queryStringParameters', {}).get('url')
    if not url:
        return {'statusCode': 400, 'headers': CORS_HEADERS, 'body': 'Missing url'}
    
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as response:
            data = response.read()
            content_type = response.headers.get('Content-Type', 'image/jpeg')
        
        return {
            'statusCode': 200,
            'headers': {**CORS_HEADERS, 'Content-Type': content_type},
            'body': base64.b64encode(data).decode('utf-8'),
            'isBase64Encoded': True
        }
    except Exception as e:
        return {'statusCode': 500, 'headers': CORS_HEADERS, 'body': 'Error'}
