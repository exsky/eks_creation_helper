import pytest
import re

from libs.connection import Connection


@pytest.mark.conn
def test_aws_credential_login():
    aws_id = Connection.awsid()
    m = re.search(r'^\d{12}$', aws_id)
    assert m is not None
