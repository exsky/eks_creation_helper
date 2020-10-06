import boto3


class Connection:
    def __init__(self, region=None):
        if not region:
            self.region = 'ap-northeast-1'

    @staticmethod
    def awsid():
        return boto3.client('sts').get_caller_identity().get('Account')
