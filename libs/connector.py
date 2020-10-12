import boto3


class Connector:
    def __init__(self, srv_name):
        self.srv_name = srv_name
        self.client = boto3.client(srv_name)

    def connect_aws_service(self):
        return self.client
