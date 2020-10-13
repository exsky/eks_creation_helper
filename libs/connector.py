import boto3
from botocore.config import Config


class Connector:

    def __init__(self, srv_name):
        # If you prefer using specific region rather than ~/.aws/credentials
        self.config = Config(
            region_name='ap-northeast-1',
            signature_version='v4',
            retries={
                'max_attempts': 10,
                'mode': 'standard'
            }
        )
        self.srv_name = srv_name
        # self.client = boto3.client(srv_name)
        self.client = boto3.client(srv_name, config=self.config)

    def connect_aws_service(self):
        return self.client
