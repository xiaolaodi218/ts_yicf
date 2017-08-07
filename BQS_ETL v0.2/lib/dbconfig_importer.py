# import the dbconfig
import sys
import json
import mysql.connector
import re

def connect(db_config):
    try:
        with open(db_config) as json_data_file:
            config = json.load(json_data_file)        
            cnx = mysql.connector.connect(**config)
            return cnx
            
    except IOError as e:
        print("I/O error({0}), {1}: {2}".format(e.errno, e.strerror, db_config))
        raise
    except:
        print("Unexpected error:", sys.exc_info()[0])
        raise
    

def connectStr(db_type, db_config):
    if db_type.lower() == 'mysql':
        port = '3306'
        charset = "?charset=utf8"
    elif db_type.lower() == 'postgresql':
        port = '5432'
        charset = ""
        
    try:
        with open(db_config) as json_data_file:
            config = json.load(json_data_file)
            str = db_type + "://" + config["user"]+":" + config["password"] + "@" + config["host"]+ ":" + port + "/" +config["database"] + charset
            return str

    except IOError as e:
        print("I/O error({0}), {1}: {2}".format(e.errno, e.strerror, db_config))
        raise
    except:
        print("Unexpected error:", sys.exc_info()[0])
        raise