# A dirt-simple mock for the EC2 metadata service, built on top of Python and Flask. It allows you to set a mock value
# for /latest/meta-data/<path> by setting the env var meta_data_<path> and the mock value for /latest/dynamic/<path>
# by setting the env var dynamic_data_<path>. Note that dashes (-) in <path> should be replaced with underscores (_)
# and slashes (/) in the path should be replaced with double underscores (__). e.g.:
#
# export meta_data_instance_id=i-1234567890abcdef0
# export meta_data_placement__availability_zone=us-west-2b
#

import os
import logging
from flask import request
from flask import Flask

app = Flask(__name__)

META_DATA_ENV_VAR_PREFIX = 'meta_data'
DYNAMIC_DATA_ENV_VAR_PREFIX = 'dynamic_data'

@app.route("/latest/api/token")
def token():
   if request.method == "PUT":
       # Return a dummy IMDSv2 token
       return "AWAAAZOnDBwzUdSPGWqQgZ4GLhHnrLIG-P1KLdlJ8Zz6kPbcIRN5lw==", 200
   else:
       return '/latest/api/token endpoint only supports PUT method', 405

@app.route("/latest/meta-data/<path:path>")
def meta_data(path):
    return lookup_path(path, META_DATA_ENV_VAR_PREFIX)

@app.route("/latest/dynamic/<path:path>")
def dynamic_data(path):
    return lookup_path(path, DYNAMIC_DATA_ENV_VAR_PREFIX)

def lookup_path(path, prefix):
    env_var_name = path_to_env_var(path, prefix)
    logging.info('Looking for env var %s' % env_var_name)
    if env_var_name in os.environ:
        return os.environ[env_var_name]
    else:
        return 'Value for environment variable %s not found' % env_var_name, 404

def path_to_env_var(path, prefix):
    return '%s_%s' % (prefix, strip_suffix(path, '/').replace('/', '__').replace('-', '_'))

def strip_suffix(str, suffix):
    if str.endswith(suffix):
        return str[:-len(suffix)]
    return str
