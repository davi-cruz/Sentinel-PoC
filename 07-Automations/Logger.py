#!/usr/bin/python3

## Get received parameters and log to a text file for demonstration purposes

import logging
import sys

## Variables
LOG_FILENAME = "/opt/sentinel/automation.log"

logging.basicConfig(filename=LOG_FILENAME,
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                    filemode='w', level=logging.INFO)

logging.info("Received parameters: " + str(sys.argv))